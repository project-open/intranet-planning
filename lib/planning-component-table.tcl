# -------------------------------------------------------------
# /packages/intranet-planning/lib/planning-component.tcl
#
# Copyright (c) 2011 ]project-open[
# All rights reserved.
#
# Author: frank.bergmann@project-open.com
#

# -------------------------------------------------------------
# Variables from intranet-planning-procs:
#	object_id:integer
#	item_cost_type_id 

# include jQuery date picker
template::head::add_javascript -src "/intranet/js/jquery-migrate-1.2.1.js" -order "50" 
template::head::add_javascript -src "/intranet/js/jquery-ui.custom.min.js" -order "99"
template::head::add_css -href "/intranet/style/jquery/overcast/jquery-ui.custom.css" -media "screen" -order "99"

# -------------------------------------------------------------
# Defaults & Parameters

set td_class(0) "class=roweven"
set td_class(1) "class=rowodd"

set name_order [parameter::get -package_id [apm_package_id_from_key intranet-core] -parameter "NameOrder" -default 1]
set currency [parameter::get_from_package_key -package_key "intranet-cost" -parameter "DefaultCurrency" -default "EUR"]


set return_url "/intranet/projects/view?project_id=$object_id"

# Users
set user_id [ad_maybe_redirect_for_registration]
set admin_p 0
if { [im_is_user_site_wide_or_intranet_admin $user_id]} { set admin_p 1 }

set item_type_id [im_planning_item_type_revenues]
set item_cost_type_id [im_cost_type_invoice]

# -------------------------------------------------------------
# Check the permissions
# Permissions for all usual projects, companies etc.

if {![info exists object_id]} { ad_return_complaint 1 "planning-component: object_id not defined" }
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id = :object_id"]
set perm_cmd "${object_type}_permissions \$user_id \$object_id object_view object_read object_write object_admin"
eval $perm_cmd
# object_read is evaluated by .adp which will return nothing if not set.

# -------------------------------------------------------------
# Building form 

# Setting titles
append body_html "<table cellspacing='1' cellpadding='1' border='0'>"
append body_html "<tr>"
append body_html "<td class=\"rowtitle\">[lang::message::lookup "" intranet-planning.ItemName "Name"]</td>"
append body_html "<td class=\"rowtitle\" align=\"right\">[lang::message::lookup "" intranet-planning.ItemValue "Value"]</td>"
# Fraber 170201: No currency for planning items!!!
# append body_html "<td class=\"rowtitle\" align=\"right\">[lang::message::lookup "" intranet-planning.ItemCurrency "Curr"]</td>"
append body_html "<td class=\"rowtitle\">[lang::message::lookup "" intranet-planning.ItemDueDate "Due date"]</td>"
append body_html "<td class=\"rowtitle\">[lang::message::lookup "" intranet-planning.ItemStatus "Status"]</td>"
append body_html "<td class=\"rowtitle\">[im_gif del [lang::message::lookup "" intranet-core.Delete "Delete"]]</td>"
append body_html "</tr>"

# Getting records 
set sql "
	select 
		i.*,
		to_char(i.item_date,'YYYY-MM-DD') as item_date_formatted 
	from 
		im_planning_items i
	where 
		item_object_id = :object_id and 
		item_cost_type_id = :item_cost_type_id
	"

set count 0
db_foreach planning_item $sql {

    # Set status 
    set item_status [im_category_select "Intranet Planning Status" "item_status_id_change.$item_id" $item_status_id]

    # set var_delete_item
    set var_delete_item "delete_item.$item_id"

    append body_html "<tr $td_class([expr $count % 2])>"
    append body_html "<td>$item_note</td>" 
    append body_html "<td align=\"right\">$item_value</td>"
    # Fraber 170201: No currency for planning items!!!
    # append body_html "<td align=\"right\">$item_currency</td>"
    append body_html "<td>$item_date_formatted</td>"
    append body_html "<td>$item_status</td>"
    append body_html "<td><input type=checkbox name='delete_item.$item_id' value=''>"
    append body_html "</tr>"
} if_no_rows {
    append body_html "<tr><td classpan=\"6\"><br/>[lang::message::lookup "" intranet-planning.NoItemsFound "No planning items found"]<br/><br/></td></tr>"
}

# Adding new entry line
append body_html "<tr><td class=\"rowtitle\" colspan='6'>[lang::message::lookup "" intranet-planning.AddNewItem "Add new Item"]</td></tr>"
append body_html "<tr>"
append body_html "<td><input type=input size=12 maxlength=12 name=\"item_note\" value=\"\"></td>" 
append body_html "<td><input type=input size=6 maxlength=6 name=\"item_value\" value=\"\"></td>" 

# Fraber 170201: No currency for planning items!!!
# append body_html "<td>[im_currency_select item_currency $currency]</td>" 
append body_html "<td><input type=input size=10 maxlength=10 name=\"item_date\" id=\"item_date\" value=\"\">"
append body_html "<td colspan='3'>[im_category_select "Intranet Planning Status" item_status_id 73000] &nbsp; <input type=submit value='[lang::message::lookup "" intranet-core.Submit "Submit"]' name=submit_apply></td>"
append body_html "</tr>"
append body_html "</table>"

# Put form together

set body_html "<form action='/intranet-planning/planning-component-table-action.tcl'>\n $body_html"
set body_html "$body_html \n </form>"






