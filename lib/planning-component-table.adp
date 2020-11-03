<form action="/intranet-planning/planning-component-table-action.tcl" onsubmit="return validateForm()" id="planning-component-table" name="planning-component-table">
<%=[export_form_vars object_id return_url item_type_id item_cost_type_id]%>
@body_html;noquote@
</form>

<script type="text/javascript" <if @::__csp_nonce@ not nil>nonce="@::__csp_nonce;literal@"</if>>
        jQuery().ready(function() {
                $(function() {
                $( "#item_date" ).datepicker({ dateFormat: "yy-mm-dd" });
                });
        });


function validateForm() {

 // A value in item_note indicates that the user likes to create a new planning item 
 var item_note = document.forms["planning-component-table"]["item_note"].value;

 if ( item_note ) {

    var x = document.forms["planning-component-table"]["item_value"].value;
    if (x == null || x == "") {
        alert("Amount must be filled out");
        return false;
    }

    // var x = document.forms["planning-component-table"]["item_currency"].value;
    // if (x == null || x == "") {
    //    alert("Currency must be filled out");
    //    return false;
    // }

    var x = document.forms["planning-component-table"]["item_date"].value;
    if (x == null || x == "") {
        alert("Date must be filled out");
        return false;
    }

    var x = document.forms["planning-component-table"]["item_status_id"].value;
    if (x == null || x == "") {
        alert("Status must be filled out");
        return false;
    }

    if ( false == $.isNumeric($("#planning-component-table input[name=item_value]").val()) ) {
        alert("Amount must be numeric, please use decimal point");
        return false;
    }

 }

}
</script>


