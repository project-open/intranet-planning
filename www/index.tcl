# /packages/intranet-planning/www//index.tcl
#
# Copyright (C) 1998-2015 Project Open Business Solutions S.L. 


# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 

    @author frank.bergmann@project-open.com
    @author klaus.hofeditz@project-open.com
} {
    { order_by "item_date" }
    { item_status_id:integer 0 } 
    { item_type_id:integer 0 } 
    { user_id_from_search 0}
    { letter:trim "" }
    { start_date "" }
    { end_date "" }
    { start_idx:integer 0 }
    { how_many "" }
    { view_name "planning_items_default" }
}

# ---------------------------------------------------------------
# 1. Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters

set show_context_help_p 0
set show_bulk_actions_p 0

set user_id [auth::require_login]
set admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set subsite_id [ad_conn subsite_id]
set current_user_id $user_id
set today [lindex [split [ns_localsqltimestamp] " "] 0]
set page_title "[_ intranet-planning.PlanningItems]"
set context_bar [im_context_bar $page_title]
set return_url [im_url_with_query]

set org_start_date $start_date
set org_end_date $end_date
set org_item_status_id $item_status_id
set org_item_type_id $item_type_id

set planning_item_status_active [im_planning_item_status_active]
set planning_item_status_deleted [im_planning_item_status_deleted]
set all_l10n [lang::message::lookup "" intranet-core.All "All"]

# Determine the default status if not set
if { 0 == $item_status_id } { set item_status_id $planning_item_status_active }

# Start / End date
if {"" eq $start_date} { set start_date [parameter::get_from_package_key -package_key "intranet-cost" -parameter DefaultStartDate -default "2010-01-01"] }
if {"" eq $end_date} { set end_date [parameter::get_from_package_key -package_key "intranet-cost" -parameter DefaultEndDate -default "2100-01-01"] }

if { [empty_string_p $how_many] || $how_many < 1 } {
    set how_many [im_parameter -package_id [im_package_core_id] NumberResultsPerPage "" 50]
}
set end_idx [expr $start_idx + $how_many]



# ---------------------------------------------------------------
# 2. Permissions
# ---------------------------------------------------------------

if {![im_permission $current_user_id "view_projects_all"]} {
    ad_return_complaint 1 " [lang::message::lookup "" intranet-planning.ViewProjectAllPermissionRequired "Viewing all Planning Items requires privilege 'View Project All'"]" 
}


# ---------------------------------------------------------------
# 3. Validation 
# ---------------------------------------------------------------

# Check that Start & End-Date have correct format
if { "" ne $start_date } {
    if {[catch {
        if { $start_date ne [clock format [clock scan $start_date] -format %Y-%m-%d] } {
            ad_return_complaint 1 "<strong>[_ intranet-core.Start_Date]</strong> [lang::message::lookup "" intranet-core.IsNotaValidDate "is not a valid date"].<br>
            [lang::message::lookup "" intranet-core.Current_Value "Current value"]: '$start_date'<br>"
        }
    } err_msg]} {
        ad_return_complaint 1 "<strong>[_ intranet-core.Start_Date]</strong> [lang::message::lookup "" intranet-core.DoesNotHaveRightFormat "doesn't have the right format"].<br>
        [lang::message::lookup "" intranet-core.Current_Value "Current value"]: '$start_date'<br>
        [lang::message::lookup "" intranet-core.Expected_Format "Expected Format"]: 'YYYY-MM-DD'"
    }
}

if { "" ne $end_date } {
    if {[catch {
        if { $end_date ne [clock format [clock scan $end_date] -format %Y-%m-%d] } {
            ad_return_complaint 1 "<strong>[_ intranet-core.End_Date]</strong> [lang::message::lookup "" intranet-core.IsNotaValidDate "is not a valid date"].<br>
            [lang::message::lookup "" intranet-core.Current_Value "Current value"]: '$end_date'<br>"
        }
    } err_msg]} {
        ad_return_complaint 1 "<strong>[_ intranet-core.End_Date]</strong> [lang::message::lookup "" intranet-core.DoesNotHaveRightFormat "doesn't have the right format"].<br>
        [lang::message::lookup "" intranet-core.Current_Value "Current value"]: '$end_date'<br>
        [lang::message::lookup "" intranet-core.Expected_Format "Expected Format"]: 'YYYY-MM-DD'"
    }
}


# ---------------------------------------------------------------
# 4. Getting View
# ---------------------------------------------------------------

set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name" -default 0]
if {!$view_id } {
    ad_return_complaint 1 "<b>Unknown View Name</b>:<br>
    The view '$view_name' is not defined. <br> Maybe you need to upgrade the database. <br> Please notify your system administrator."
    return
}

set column_headers [list]
set column_vars [list]
set column_headers_admin [list]
set extra_selects [list]
set extra_froms [list]
set extra_wheres [list]
set view_order_by_clause ""

set column_sql "
	select
		vc.*
	from
		im_view_columns vc
	where
		view_id=:view_id
		and group_id is null
	order by
		sort_order"

db_foreach column_list_sql $column_sql {

    set admin_html ""
    if {$admin_p} { 
	set url [export_vars -base "/intranet/admin/views/new-column" {column_id return_url}]
	set admin_html "<a href='$url'>[im_gif wrench ""]</a>" 
    }

    if {"" eq $visible_for || [eval $visible_for]} {
	lappend column_headers "$column_name"
	lappend column_vars "$column_render_tcl"
	lappend column_headers_admin $admin_html
	if {"" ne $extra_select} { lappend extra_selects $extra_select }
	if {"" ne $extra_from} { lappend extra_froms $extra_from }
	if {"" ne $extra_where} { lappend extra_wheres $extra_where }
	if {"" ne $order_by_clause &&
	    $order_by==$column_name} {
	    set view_order_by_clause $order_by_clause
	}
    }
}

# ---------------------------------------------------------------
# 5. Build Form
# ---------------------------------------------------------------

set menu_select_label ""
switch $item_status_id {
    "$planning_item_status_active" { set menu_select_label "planning_item_status_active" }
    "planning_item_status_deleted" { set menu_select_label "planning_item_status_deleted" }
    default { set menu_select_label "planning_item_status_active" }
}


set form_id "planning_items"
set action_url "/intranet-planning/index"
set form_mode "edit"

ad_form \
    -name $form_id \
    -action $action_url \
    -mode $form_mode \
    -method GET \
    -export {start_idx order_by how_many view_name letter filter_advanced_p}\
    -form {}

ad_form -extend -name $form_id -form {
    {item_status_id:text(im_category_tree),optional {label #intranet-planning.PlanningStatus#} {value $item_status_id} {custom {category_type "Intranet Planning Status" translate_p 1 include_empty_name $all_l10n}} }
    {item_type_id:text(im_category_tree),optional {label #intranet-planning.PlanningType#} {value $item_type_id} {custom {category_type "Intranet Planning Type" translate_p 1 include_empty_name $all_l10n} } }
    {start_date:text(text) {label "[_ intranet-timesheet2.Start_Date]"} {value "$start_date"} {html {size 10}} {after_html {<input id=start_date_calendar type="button" style="height:20px; width:20px; background: url('/resources/acs-templating/calendar.gif');" >}}}
    {end_date:text(text) {label "[_ intranet-timesheet2.End_Date]"} {value "$end_date"} {html {size 10}} {after_html {<input id=end_date_calendar type="button" style="height:20px; width:20px; background: url('/resources/acs-templating/calendar.gif');"  >}}}

} 

set filter_admin_html ""

# ---------------------------------------------------------------
# 5. Generate SQL Query
# ---------------------------------------------------------------

set criteria [list]
if { ![empty_string_p $item_status_id] && $item_status_id > 0 } {
    lappend criteria "i.item_status_id in ([join [im_sub_categories $item_status_id] ","])"
}
if { ![empty_string_p $item_type_id] && $item_type_id != 0 } {
    lappend criteria "i.item_type_id in ([join [im_sub_categories $item_type_id] ","])"
}

if {"" ne $start_date} {
    lappend criteria "i.item_date >= :start_date::timestamptz"
}
if {"" ne $end_date} {
    lappend criteria "i.item_date < :end_date::timestamptz"
}


set order_by_clause "order by item_date DESC"
switch [string tolower $order_by] {
    "item_date" { set order_by_clause "order by item_date DESC" }
    "item_status" { set order_by_clause "order by item_status_id" }
    "item_type" { set order_by_clause "order by item_type_id desc" }
    "project manager" { set order_by_clause "order by lower(lead_name)" }
    "project name" { set order_by_clause "order by lower(project_name)" }
    default { set order_by_clause "order by item_date DESC" }
}


set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}

set extra_select [join $extra_selects ",\n\t"]
if { ![empty_string_p $extra_select] } {
    set extra_select ",\n\t$extra_select"
}

set extra_from [join $extra_froms ",\n\t"]
if { ![empty_string_p $extra_from] } {
    set extra_from ",\n\t$extra_from"
}

set extra_where [join $extra_wheres "and\n\t"]
if { ![empty_string_p $extra_where] } {
    set extra_where ",\n\t$extra_where"
}

# Create a ns_set with all local variables in order
# to pass it to the SQL query
set form_vars [ns_set create]
foreach varname [info locals] {

    # Don't consider variables that start with a "_", that
    # contain a ":" or that are array variables:
    if {"_" == [string range $varname 0 0]} { continue }
    if {[regexp {:} $varname]} { continue }
    if {[array exists $varname]} { continue }

    # Get the value of the variable and add to the form_vars set
    set value [expr "\$$varname"]
    ns_set put $form_vars $varname $value
}

set sql "
        SELECT
                i.*,
                im_name_from_user_id(p.project_lead_id) as lead_name,
		p.project_name,
		p.project_id,
                im_category_from_id(i.item_type_id) as item_type,
                im_category_from_id(i.item_status_id) as item_status,
                to_char(i.item_date, 'YYYY-MM-DD') as item_date_formatted
		$extra_select
        FROM
		im_planning_items i,
		im_projects p
		$extra_from
        WHERE
		i.item_object_id = p.project_id
                $where_clause
		$extra_where
	$order_by_clause
"

# ---------------------------------------------------------------
# 5a. Limit the SQL query to MAX rows and provide << and >>
# ---------------------------------------------------------------

# Limit the search results to N data sets only
# to be able to manage large sites

# ns_log Notice "/intranet/project-planning/index: Before limiting clause"

# We can't get around counting in advance if we want to be able to
# sort inside the table on the page for only those users in the
# query results
set total_in_limited [db_string total_in_limited "
        select count(*)
        from ($sql) s
"]

# Special case: FIRST the users selected the 2nd page of the results
# and THEN added a filter. Let's reset the results for this case:
while {$start_idx > 0 && $total_in_limited < $start_idx} {
    set start_idx [expr $start_idx - $how_many]
    set end_idx [expr $end_idx - $how_many]
}

set selection [im_select_row_range $sql $start_idx $end_idx]


# ---------------------------------------------------------------
# 6. Format the Filter
# ---------------------------------------------------------------

# Note that we use a nested table because im_slider might
# return a table with a form in it (if there are too many
# options

# ns_log Notice "/intranet-planning/index: Before formatting filter"

# ---------------------------------------------------------------
# 7. Format the List Table Header
# ---------------------------------------------------------------

# Set up colspan to be the number of headers + 1 for the # column
# ns_log Notice "/intranet/project-planning/index: Before format header"
set colspan [expr [llength $column_headers] + 1]

set table_header_html ""

# Format the header names with links that modify the sort order of the SQL query.
set url "index?"
set query_string [export_ns_set_vars url [list order_by]]
if { ![empty_string_p $query_string] } {
    append url "$query_string&"
}

append table_header_html "<tr>\n"
set ctr 0
foreach col $column_headers {
    set wrench_html [lindex $column_headers_admin $ctr]
    regsub -all " " $col "_" col_txt
    set col_txt [lang::message::lookup "" intranet-planning.$col_txt $col]
    if {$ctr == 0 && $show_bulk_actions_p} {
	append table_header_html "<td class=rowtitle>$col_txt$wrench_html</td>\n"
    } else {
	#set col [lang::util::suggest_key $col]
	append table_header_html "<td class=rowtitle><a href=\"${url}order_by=[ns_urlencode $col]\">$col_txt</a>$wrench_html</td>\n"
    }
    incr ctr
}
append table_header_html "</tr>\n"


# ---------------------------------------------------------------
# 8. Format the Result Data
# ---------------------------------------------------------------

# ns_log Notice "/intranet/project-planning/index: Before db_foreach"

set table_body_html ""
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "
set ctr 0
set idx $start_idx

db_foreach projects_info_query $selection -bind $form_vars {

#    if {"" == $project_id} { continue }

    set item_type [im_category_from_id $item_type_id]
    set item_status [im_category_from_id $item_status_id]

    # Multi-Select
    set select_project_checkbox "<input type=checkbox name=select_item_id value=$item_id id=select_item_id,$item_id>"

    # Gif for collapsable tree?
    set gif_html ""

    set url [im_maybe_prepend_http $url]
    if { [empty_string_p $url] } {
	set url_string "&nbsp;"
    } else {
	set url_string "<a href=\"$url\">$url</a>"
    }

    # Append together a line of data based on the "column_vars" parameter list
    set row_html "<tr$bgcolor([expr $ctr % 2])>\n"
    foreach column_var $column_vars {
	append row_html "\t<td valign=top>"
	set cmd "append row_html $column_var"
	if [catch {
	    eval "$cmd"
	} errmsg] {
            global errorInfo
            ns_log Error $errorInfo
	    ad_return_complaint xx $errorInfo
	}
	append row_html "</td>\n"
    }
    append row_html "</tr>\n"
    append table_body_html $row_html

    incr ctr
    if { $how_many > 0 && $ctr > $how_many } {
	break
    }
    incr idx
}

# Show a reasonable message when there are no result rows:
if { [empty_string_p $table_body_html] } {
    set table_body_html "
        <tr><td colspan=$colspan><ul><li><b> 
	[lang::message::lookup "" intranet-core.lt_There_are_currently_n "There are currently no entries matching the selected criteria"]
        </b></ul></td></tr>"
}

if { $end_idx < $total_in_limited } {
    # This means that there are rows that we decided not to return
    # Include a link to go to the next page
    set next_start_idx [expr $end_idx + 0]
    set next_page_url "index?start_idx=$next_start_idx&amp;[export_ns_set_vars url [list start_idx]]"
} else {
    set next_page_url ""
}

if { $start_idx > 0 } {
    # This means we didn't start with the first row - there is
    # at least 1 previous row. add a previous page link
    set previous_start_idx [expr $start_idx - $how_many]
    if { $previous_start_idx < 0 } { set previous_start_idx 0 }
    set previous_page_url "index?start_idx=$previous_start_idx&amp;[export_ns_set_vars url [list start_idx]]"
} else {
    set previous_page_url ""
}

# ---------------------------------------------------------------
# 9. Format Table Continuation
# ---------------------------------------------------------------

# ns_log Notice "/intranet/project-planning/index: before table continuation"
# Check if there are rows that we decided not to return
# => include a link to go to the next page
#
if {$total_in_limited > 0 && $end_idx < $total_in_limited} {
    set next_start_idx [expr $end_idx + 0]
    set next_page "<a href=index?start_idx=$next_start_idx&amp;[export_ns_set_vars url [list start_idx]]>Next Page</a>"
} else {
    set next_page ""
}

# Check if this is the continuation of a table (we didn't start with the
# first row - there is at least 1 previous row.
# => add a previous page link
#
if { $start_idx > 0 } {
    set previous_start_idx [expr $start_idx - $how_many]
    if { $previous_start_idx < 0 } { set previous_start_idx 0 }
    set previous_page "<a href=index?start_idx=$previous_start_idx&amp;[export_ns_set_vars url [list start_idx]]>Previous Page</a>"
} else {
    set previous_page ""
}

set table_continuation_html "
<tr>
  <td align=center colspan=$colspan>
    [im_maybe_insert_link $previous_page $next_page]
  </td>
</tr>"

if {$show_bulk_actions_p} {
    set table_continuation_html "
	<tr>
	<td colspan=99>[im_project_action_select]</td>
	</tr>
$table_continuation_html
    "
}


# ---------------------------------------------------------------
# Dashboard column
# ---------------------------------------------------------------

set dashboard_column_html [string trim [im_component_bay "right"]]
if {"" eq $dashboard_column_html} {
    set dashboard_column_width "0"
} else {
    set dashboard_column_width "250"
}


# ---------------------------------------------------------------
# Navbars
# ---------------------------------------------------------------

# Get the URL variables for pass-though
set query_pieces [split [ns_conn query] "&"]
set pass_through_vars [list]
foreach query_piece $query_pieces {
    if {[regexp {^([^=]+)=(.+)$} $query_piece match var val]} {
	# exclude "form:...", "__varname" and "letter" variables
	if {[regexp {^form} $var match]} {continue}
	if {[regexp {^__} $var match]} {continue}
	set var [ns_urldecode $var]
	lappend pass_through_vars $var
    }
}

set start_date $org_start_date
set end_date $org_end_date
set item_status_id $org_item_status_id
set item_type_id $org_item_type_id

# Compile and execute the formtemplate if advanced filtering is enabled.
eval [template::adp_compile -string {<formtemplate id="planning_items" style="tiny-plain-po"></formtemplate>}]
set filter_html $__adp_output

# Left Navbar is the filter/select part of the left bar
set left_navbar_html "
	<div class='filter-block'>
        	<div class='filter-title'>
	           [_ intranet-core.Filter_Projects] $filter_admin_html
        	</div>
            	$filter_html
      	</div>
"
