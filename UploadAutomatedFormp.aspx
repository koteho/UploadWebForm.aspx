<%@ Page Language="C#" %>
<!DOCTYPE html>
<html>
<head runat="server">
	<meta charset="UTF-8">
    <title>Upload Test Data Front End</title>
	
	<script type="text/javascript">
		//Auto Fill Fields needed for file saving. Updated by XML data values
		var textArea;
		var cID;
		var mID;
		var gameName;
		var userName;
		
		//Status Header Vars
		var statusHeader;
		var statusMsg = "<%=Request["statusMsg"]%>";
	
		//XML Template Vars and functions
		var serverPath;
		var selectTemplate;
		var templateNames = [];
		var templateXML   = [];
		
		//Backend C# server code will fill the names array and path for javascript here.
		<%
			const string targetDir = @"XMLTemplates/UploadAutomated/";
			string[] fileEntries = System.IO.Directory.GetFiles(Server.MapPath(targetDir));
		%>
		serverPath = "<%=targetDir%>";
		
		<% for(int i=0; i< fileEntries.Length;++i) {
			
			//invalid string length
			if(fileEntries[i].Length < 3)
				continue;
			
			//check if xml file - no validation on this end.
			if(fileEntries[i].Substring(fileEntries[i].Length-3).ToUpper()!="XML")
				continue;				
			
			string[] splitter = fileEntries[i].Split('\\');
			string fName = splitter[splitter.Length-1];
		%>
			templateNames.push("<%=fName%>");
		<% } %>
		
		var xhttpReqs = []; 
		function LoadXMLTemplates()
		{
			for(var i=0;i<templateNames.length;i++)
			{
				xhttpReqs[i] = new XMLHttpRequest();
				xhttpReqs[i].currentIndex = i;
				
				xhttpReqs[i].onreadystatechange = function(){
					if (this.readyState == 4 && this.status == 200) {
						templateXML[this.currentIndex] = this.responseText;						
					}
				};
				//alert(serverPath + templateNames[i]);
				xhttpReqs[i].open("GET", serverPath + templateNames[i], true);
				xhttpReqs[i].send();
			}
		}
		
		//Do not wait for full window load.Load the templates ASAP so we can use the page ASAP.
		LoadXMLTemplates();
	
		//Core functionality Functions.
		
		function OnXMLChange()
		{
			//make sure the inputs are valid
			if(!NullChecker())
				return;
			
			//Convert the text area text to xml.
			var parser     = new DOMParser();
			var xml		   = parser.parseFromString(textArea.value,"text/xml");
			
			statusMsg	   = "";
			UpdateStatusHeader(statusMsg);
			
			if(xml.getElementsByTagName("parsererror")[0]!==undefined)
			{
				alert("The text provided is not valid XML. Please try again.\n");
				return;
			}
			
			var keyElement = xml.getElementsByTagName("Key")[0];
			cID.value 	   = keyElement.attributes["clientID"].value;
			mID.value 	   = keyElement.attributes["moduleID"].value;
			gameName.value = keyElement.attributes["gameName"].value;
			userName.value = keyElement.attributes["loginName"].value;			
		};
		
		function UpdateStatusHeader(textToDisplay)
		{
			if(statusHeader===undefined)
				return;
			
			statusHeader.innerHTML = textToDisplay;
		};
		
		//sets the xml from a template into the text area. called when Select box is changed.
		function SetTemplate()
		{
			var index = selectTemplate.options[selectTemplate.selectedIndex].value;
			
			if(index<0)
				textArea.value = "";
			else if(selectTemplate!==undefined)
				textArea.value = templateXML[index];
		};
		
		//checks to make sure the needed global vars were set properly, returns true for good false if there is a problem.
		function NullChecker()
		{
			var errs = "";
			var valid = true;
			
			if(textArea===undefined)
			{
				errs = errs + "\n The text area for test data could not be found.";
				valid = false;
			}
			
			if(cID===undefined)
			{
				errs = errs + "\n The client id field could not be found.";
				valid = false;
			}
			
			if(mID===undefined)
			{
				errs = errs + "\n The moudule id field could not be found.";
				valid = false;
			}
			
			if(gameName===undefined)
			{
				errs = errs + "\n The moudule id field could not be found.";
				valid = false;
			}
			
			if(userName===undefined)
			{
				errs = errs + "\n The user name field could not be found.";
				valid = false;
			}
			
			if(statusHeader===undefined)
			{
				errs = errs + "\n The Status Header could not be found.";
				valid = false;
			}
			
			if(valid)
			{
				return true;
			}
			else
			{
				errs = errs + "\n Please try refreshing the page. If problem persists, yell at Preston.";
				alert(errs);
				return false;
			}
			
		};
		
		window.onload = function(){
			textArea = document.getElementById("testData");
			cID = document.getElementById("cID");
			mID = document.getElementById("mID");
			gameName = document.getElementById("gameName");
			userName = document.getElementById("userName");
			statusHeader = document.getElementById("statusHeader");
			selectTemplate = document.getElementById("selectTemplate");
			UpdateStatusHeader(statusMsg);
			
			//alert(selectTemplate);
			if(selectTemplate!=null && selectTemplate!==undefined)
			{
				for(var i=0;i<templateNames.length;++i)
				{
					var opt = document.createElement("option");
					opt.setAttribute("value",i);
					opt.innerHTML = templateNames[i];
					selectTemplate.appendChild(opt);
				}
			}
		};
	</script>
</head>
<body>
	<h1>Upload Test Data Front End - <%=Environment.MachineName%></h1>
	<h3 id="statusHeader" style="color:green;"></h3>
	
    <form name="form1" runat="server" method="post" action="../UploadAutomated.ashx">
		<div>
			Client ID:<input type="text" id="cID" name="cID" readonly/>
			Module ID:<input type="text" id="mID" name="mID" readonly/>
			Game Name:<input type="text" id="gameName" name="gameName" readonly/>
			User Name:<input type="text" id="userName" name="userName" readonly>
			&nbsp;&nbsp;<input type="submit" name="submit" value="Upload Data"/>
			<br/><br/>
			Template: <select id="selectTemplate" onchange="SetTemplate();">
				<option value="-1"></option>
				<!-- Populated by JS -->
			</select>
			<br/><br/>
			Test Data:<br/>
			<textarea id="testData" name="testData" rows="30" cols="100" onchange="OnXMLChange()"><%=Request["testData"]%></textarea>
			
			<input type="hidden" name="reDir" value="<%=Request.Url.AbsolutePath%>"/>
			
		</div>
    </form>
</body>
</html>