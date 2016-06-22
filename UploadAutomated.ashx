<%@ WebHandler Language="C#" Class="PostHandler" %>	
	/*
	* UploadedAutomated.ashx

	* Language:C# - ashx (Generic Handler)
	* Takes in test data in write to 
	* Test data should be in the xml format used to test the reels.
	* See examples on the server in the test data folder.
	* This program is used by Ranorex for automated requests but can also be used with the front end at UploadAutomatedForm.aspx.
	*/

	using System;
	using System.Web;
	using System.IO;
	using System.Xml;
	using System.Xml.Linq;
	
	public class PostHandler : IHttpHandler
	{
		#region IHttpHandler Members
			public bool IsReusable
			{
				get { return true; }
			}
			
			public void ProcessRequest (HttpContext context) 
			{
				context.Response.ContentType = "text/plain";
				context.Response.ContentEncoding = System.Text.Encoding.UTF8;			
				
				//Validate we have all the proper parameters to process the request.
				string errs = "";
				bool validRequest = true;
				
				//the actual test data to write
				string inputXML = context.Request.Unvalidated.Form["testData"];
				if(String.IsNullOrEmpty(inputXML))
				{
					errs = errs + "\n'testData' parameter is requried and missing. Please give testdata to write.";
					validRequest = false;
				}
				
				//user account
				if(String.IsNullOrEmpty(context.Request["userName"]))
				{
					errs = errs + "\n'userName' parameter is requried and missing.";
					validRequest = false;
				}
				
				//module id
				int moduleID=-1;
				if(String.IsNullOrEmpty(context.Request["mID"]))
				{
					errs = errs +"\n'mID' parameter is requried and missing. Please enter a module id.";
					validRequest = false;
				}
				else if(!Int32.TryParse(context.Request["mID"], out moduleID))
				{
					errs = errs +"\n'mID' parameter is requried and not an int. Please enter a module id.";
					validRequest = false;
				}
				
				//client id
				int clientID=-1;
				if(String.IsNullOrEmpty(context.Request["cID"]))
				{
					errs = errs +"\n'cID' parameter is requried and missing. Please enter a client id.";
					validRequest = false;
				}
				else if(!Int32.TryParse(context.Request["cID"], out clientID))
				{
					errs = errs + "\n'cID' parameter is requried and not an int. Please enter a client id.";
					validRequest = false;
				}
				
				//Game Name
				if(String.IsNullOrEmpty(context.Request["gameName"]))
				{
					errs = errs + "\n'gameName' parameter is requried and missing.";
					validRequest = false;
				}
				
				//make sure the testdata is valid xml.
				XElement xml;				
				try
				{
					xml = XElement.Parse(inputXML);
				}
				catch(XmlException xmlException)
				{
					errs = errs + "\nXML test data is malformed.";
					validRequest = false;
				}			
				xml = null;
				
				//if something went wrong, now is the time to error out and stop.
				if(!validRequest)
					ThrowError(context,errs,400,"400 Bad Request");
				
				//If we make it here then we should have some data to write.
				//Setup and do it.
				string filePath = @"C:\MGS_Data\x86\VeyronGames\testdata\"+context.Request["gameName"]+"_"+moduleID+"_"+clientID+"_"+context.Request["username"]+".testdata";
				
				try
				{
					//Existing file will be overwritten, catch any errors and manually report to client.
					StreamWriter writer = File.CreateText(filePath);
					writer.Write(inputXML);
					writer.Flush();
					writer.Close();
					writer = null;
				}
				catch(Exception e)
				{
					ThrowError(context,"There was an error writing the data to "+Environment.MachineName +". Additionaly the server reports: "+e.Message,500,"500 Internal Server Error - Could Not Write Data.");
				}	

				//If there is a redirect (aka from a web form and not automated) then process it.
				if(!String.IsNullOrEmpty(context.Request["reDir"]))
					context.Response.Redirect(context.Request["reDir"]+"?statusMsg=Test Data succesfully uploaded!");
			}
		#endregion
		
		#region HelperFunctions
			public void ThrowError (HttpContext context,string errMsg,int httpCode,string statusString)
			{
				context.Response.ClearHeaders();
				context.Response.ClearContent(); 
				context.Response.Status = statusString;
				context.Response.StatusCode = httpCode;
				context.Response.StatusDescription = "An error has occurred. "+errMsg;
				context.Response.ContentType = "text/html";
				throw new HttpException(httpCode,string.Format("Your client has sent a bad request for the script. Please make sure all parameters are filled out properly. Further more the script reports: "+errMsg,Environment.MachineName));  
				context.Response.End();
			}
		#endregion
	}
	

