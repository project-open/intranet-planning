# /packages/intranet-planning/www/planning-component-table-action.tcl
#
# Copyright (C) 1998-2015 various parties

ad_page_contract {
    Sets or updates Employee/Company Price Matrix   
    @author various@arsdigita.com
    @author frank.bergmann@project-open.com
    @author klaus.hofeditz@project-open.com
} {
    object_id:integer
    delete_item:array,optional
    item_status_id_change:array,optional
    item_note:optional
    item_value:optional
    item_date:optional
    item_status_id:optional
    item_type_id:optional
    item_cost_type_id:optional
    { return_url "" }
    { submit "" }
}

# -----------------------------------------------------------------
# Security & Defaults
# -----------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]

# Determine our permissions for the current object_id.
# We can build the permissions command this ways because
# all ]project-open[ object types define procedures
# im_ObjectType_permissions $user_id $object_id view read write admin.
#
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id=:object_id"]
set perm_cmd "${object_type}_permissions \$current_user_id \$object_id view read write admin"
eval $perm_cmd

if {!$write} {
    ad_return_complaint 1 "You have no rights to create planning items for this object"
    ad_script_abort
}

if { ![info exists new_amount] } { set new_amount "" }

# -----------------------------------------------------------------
# Actions
# -----------------------------------------------------------------

# Delete items 
foreach item_id [array names delete_item] {
    if {[catch {
	db_dml delete_planning_item "delete from im_planning_items where item_id = :item_id"
    } err_msg]} {
	global errorInfo
	ns_log Error "intranet-planning::planning-table-view-action - deleting planning item failed: " $errorInfo
    }
}

# Update Items 
foreach item_id [array names item_status_id_change] {

    set item_status_id_change_status_id $item_status_id_change($item_id)
    if {[catch {
        db_dml update_item "update im_planning_items set item_status_id = :item_status_id_change_status_id where item_id = :item_id"
    } err_msg]} {
        global errorInfo
        ns_log Error "intranet-planning::planning-table-view-action - deleting planning item failed: " $errorInfo
    }
}


# Create new item 
set ctr 0 

# A value in item_note indicates that the user wants to create a new planning item
if { "" ne $item_note } {

    # Mandatory fields are checked already using client side JS, just do a simple validation 
    if { "" ne $item_value } { incr ctr }
    if { "" ne $item_date } { incr ctr }
    if { "" ne $item_status_id } { incr ctr }

    if { $ctr < 3 } {
        ns_log Notice "intranet-planning::planning-component-table-action: Error creating planning item, variable missing"
    } else {
        # Create new item
        if {[catch {
	    set item_id [db_string nextval "select nextval('im_planning_items_seq')"]
            db_dml sql "
		insert into im_planning_items 
			(item_id,item_note,item_type_id,item_cost_type_id,item_value,item_date,item_status_id,item_object_id) values 
			(:item_id,:item_note,:item_type_id,:item_cost_type_id,:item_value,:item_date,:item_status_id,:object_id)
		"
        } err_msg]} {
            global errorInfo
            ns_log Error "intranet-planning::planning-component-table-action: Error creating planing item: $errorInfo"
        }
    }
} 

ad_returnredirect $return_url
