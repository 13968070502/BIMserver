<%@page import="org.bimserver.interfaces.objects.SLongActionState"%>
<%@page import="java.util.Set"%>
<%@page import="java.util.HashSet"%>
<%@page import="org.slf4j.LoggerFactory"%>
<jsp:useBean id="loginManager" scope="session" class="org.bimserver.web.LoginManager" />
<%
	try {
		long roid = Long.parseLong(request.getParameter("roid"));
		String serializerName = "Ifc2x3";
		if (request.getParameter("serializerName") != null) {
			serializerName = request.getParameter("serializerName");
		}
		String zip = request.getParameter("zip");
		int longActionId = -1;
		if (request.getParameter("checkout") != null) {
			longActionId = loginManager.getService().checkout(roid,	serializerName, false);
		} else if (request.getParameter("download") != null) {
			if (request.getParameter("guids") != null){
				Set<String> guids = new HashSet<String>();
				for (String guid : request.getParameter("guids").split(";")) {
					guids.add(guid);
				}
				Set<Long> roids = new HashSet<Long>();
				roids.add(roid);
				longActionId = loginManager.getService().downloadByGuids(roids, guids, serializerName, false);
			} else if (request.getParameter("oids") != null) {
				Set<Long> oids = new HashSet<Long>();
				for (String oidString : request.getParameter("oids").split(";")) {
					oids.add(Long.parseLong(oidString));
				}
				Set<Long> roids = new HashSet<Long>();
				roids.add(roid);
				longActionId = loginManager.getService().downloadByOids(roids, oids, serializerName, false);
			} else if (request.getParameter("classes") != null){
				Set<String> classes = new HashSet<String>();
				for (String className : request.getParameter("classes").split(";")) {
					classes.add(className);
				}
				Set<Long> roids = new HashSet<Long>();
				roids.add(roid);
				longActionId = loginManager.getService().downloadByTypes(roids, classes, serializerName, false);
			} else if (request.getParameter("multiple") != null){
				Set<Long> roids = new HashSet<Long>();
				for (Object key : request.getParameterMap().keySet()) {
					String keyString = (String) key;
					if (keyString.startsWith("download_")) {
						if (!request.getParameter(keyString).equals("[off]")) {
							roids.add(Long.parseLong(request.getParameter(keyString)));
						}
					}
				}
				longActionId = loginManager.getService().downloadProjects(roids, serializerName, false);
			} else {
				longActionId = loginManager.getService().download(roid, serializerName, false);
			}
		}
		SLongActionState las = loginManager.getService().getDownloadState(longActionId);
%>

<div id="progressBar<%=longActionId%>">
</div>
<span id="statusfield<%=longActionId%>">
</span>

<script>
	var downloadUpdateFunctionHandle;
	
	var downloadUpdateFunction = function() {
		$.ajax({
			url: "progress?laid=<%=longActionId%>",
			cache: false,
			context: document.body,
			error: function(){
			},
			success:
				function(data){
					$("#progressBar<%=longActionId%>").progressbar("value", data.progress);
					$("#statusfield<%=longActionId%>").html("<nobr>Preparing (" + data.progress + "%)</nobr>");
					if (data.progress == 100) {
						clearInterval(downloadUpdateFunctionHandle);
						$("#progressBar<%=longActionId%>").hide();
						$("#statusfield<%=longActionId%>").hide();
						$(".downloadResult").hide();
						window.location = 'download?longActionId=<%=longActionId%><%=(zip == null ? "" : ("&zip=" + zip))%>&serializerName=<%=serializerName%>';
					}
				},
			data: {	longActionId: '<%=longActionId%>' ,
					zip: '<%=zip%>'
				}
			});
	};

	$(document).ready(function() {
		$("#progressBar<%=longActionId%>").progressbar({value: <%=las.getProgress()%>});
		$("#statusfield<%=longActionId%>").html("<nobr>Preparing (" + <%=las.getProgress()%> + "%)</nobr>");
		downloadUpdateFunctionHandle = window.setInterval(downloadUpdateFunction, 1000);
		downloadUpdateFunction();
	});
</script>
<%
	} catch (Exception e) {
		LoggerFactory.getLogger("initiatedownload.jsp").error("", e);
	}
%>