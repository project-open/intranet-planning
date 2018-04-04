ad_library {
    Initialization for intranet-planning

    @author Frank Bergmann (frank.bergmann@project-open.com)
    @author Klaus Hofeditz (klaus.hofeditz@project-open.com)

    @creation-date 16 August, 2017
    @cvs-id $Id$
}


ad_proc -public -callback im_planning_after_action {
    {-object_id:required}
    {-action:required}
} {
    Callback to be executed after a planning action
} -


