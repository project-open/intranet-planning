# /packages/intranet-planning/tcl/intranet-planning-procs.tcl
#
# Copyright (C) 2003-2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------

ad_proc -public im_planning_item_status_active {} { return 73000 }
ad_proc -public im_planning_item_status_deleted {} { return 73002 }
ad_proc -public im_planning_item_status_archived {} { return 73004 }

ad_proc -public im_planning_item_type_revenues {} { return 73100 }
ad_proc -public im_planning_item_type_costs {} { return 73102 }
ad_proc -public im_planning_item_type_hours {} { return 73104 }


# ----------------------------------------------------------------------
# Components
# ---------------------------------------------------------------------

ad_proc -public im_planning_component {
    {-planning_type_id 73100 }
    {-top_dimension "" }
    {-left_dimension "" }
    {-planning_dimension_date "" }
    {-planning_dimension_cost_type "" }
    {-restrict_to_main_project_p 1 }
    -object_id
} {
    Returns a HTML component to show all object related planning items.
    Default values indicate type "Revenue" planning by time dimension "Month".
    No planning dimensions are specified by default, so that means planning
    per project and sub-project normally.
} {
    im_security_alert_check_integer -location "im_planning_component" -value $object_id

    # Skip evaluating the component if we are not in a main project
    set parent_id [util_memoize [list db_string parent "select parent_id from im_projects where project_id = $object_id" -default ""]]
    if {$restrict_to_main_project_p && "" != $parent_id} { return "" }

    set params [list \
		    [list object_id $object_id] \
		    [list planning_type_id $planning_type_id] \
		    [list top_dimension $top_dimension] \
		    [list left_dimension $left_dimension] \
		    [list planning_dimension_date $planning_dimension_date] \
		    [list planning_dimension_cost_type $planning_dimension_cost_type] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-planning/lib/planning-component"]
    return [string trim $result]
}


ad_proc -public im_planning_table_view_component {
    {-planning_type_id 73100 }
    {-item_cost_type_id 3700 }    
    {-restrict_to_main_project_p 1 }
    -object_id
} {
    Returns a HTML component that shows all planning items
    in a table view, allowing to add a new item.  

} {
    im_security_alert_check_integer -location "im_planning_component" -value $object_id

    # Skip evaluating the component if we are not in a main project
    set parent_id [util_memoize [list db_string parent "select parent_id from im_projects where project_id = $object_id" -default ""]]
    if {$restrict_to_main_project_p && "" != $parent_id} { return "" }

    set params [list \
		    [list object_id $object_id] \
		    [list planning_type_id $planning_type_id] \
                    [list item_cost_type_id $item_cost_type_id] \
    ]

    return [string trim [ad_parse_template -params $params "/packages/intranet-planning/lib/planning-component-table"]]
}

