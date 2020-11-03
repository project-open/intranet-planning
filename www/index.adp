<master>
<property name="title">@page_title@</property>
<property name="context">#intranet-core.context#</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>
<property name="show_context_help">@show_context_help_p;noquote@</property>

<!-- Show calendar on start- and end-date -->
<script type="text/javascript" <if @::__csp_nonce@ not nil>nonce="@::__csp_nonce;literal@"</if>>
window.addEventListener('load', function() { 
     document.getElementById('start_date_calendar').addEventListener('click', function() { showCalendar('start_date', 'y-m-d'); });
     document.getElementById('end_date_calendar').addEventListener('click', function() { showCalendar('end_date', 'y-m-d'); });
});
</script>

	<table cellspacing=0 cellpadding=0 border=0 width="100%">
	<tr valign=top>
	<td>
		<table class="table_list_page">
	            <%= $table_header_html %>
	            <%= $table_body_html %>
	            <%= $table_continuation_html %>
		</table>
		</form>
	</td>
	</tr>
	</table>


