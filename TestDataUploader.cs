/*
 * Created by Ranorex
 * User: PavloK
 * Date: 3/2/2016
 * Time: 2:39 PM
 *
 * This module takes in a file name of an xml file in the External/XML folder and process it.
 * The processing includes reading in game name,module id,client id, and user name information and then uploading it to a specified server. By default the server is CasinoAS1.
 */
using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
using System.Drawing;
using System.Threading;
using WinForms = System.Windows.Forms;

using Ranorex;
using Ranorex.Core;
using Ranorex.Core.Testing;

using System.IO;
using System.Xml;
using System.Xml.Linq;
using System.Linq;
using System.Net;

namespace Console.Tools
{
    /// <summary>
    /// Description of TestDataUploader.
    /// </summary>
    [TestModule("BB684505-4545-4CC5-B17A-877C56303F0F", ModuleType.UserCode, 1)]
    public class TestDataUploader : ITestModule
    {
        /// <summary>
        /// Constructs a new instance.
        /// </summary>
        public TestDataUploader()
        {
            // Do not delete - a parameterless constructor is required!
        }


        string _ServerProgramAddress = "casinoas1/UploadAutomated.ashx";
        [TestVariable("4F1281E0-DD14-409A-881A-D63B4EE806B8")]
        public string ServerProgramAddress
        {
            get { return _ServerProgramAddress; }
            set { _ServerProgramAddress = value; }
        }

        //When inputing the XML file name, please include file extension. This allows for .xml or .textdata files.
        string _FileName = "";
        [TestVariable("124064B4-F955-40F4-8631-DAB30CFDE992")]
        public string FileName
        {
            get { return _FileName; }
            set { _FileName = value; }
        }


        string _GameName = "KFC";
        [TestVariable("D5838FB4-775D-4E6E-BEF4-42B1F14AA479")]
        public string GameName
        {
            get { return _GameName; }
            set { _GameName = value; }
        }


        /// <summary>
        /// Performs the playback of actions in this module.
        /// </summary>
        /// <remarks>You should not call this method directly, instead pass the module
        /// instance to the <see cref="TestModuleRunner.Run(ITestModule)"/> method
        /// that will in turn invoke this method.</remarks>
        void ITestModule.Run()
        {
            Mouse.DefaultMoveTime = 300;
            Keyboard.DefaultKeyPressTime = 100;
            Delay.SpeedFactor = 1.0;

            //Validate file and read it in. 
            //string standAloneConcatPath = @"\..\..";//if running this module stand alone, concat this onto the start of the imagePath below to adjust proper path(runs from exe path here and not test case path in project base.)
            string fullRelPath = /*standAloneConcatPath +*/ @"\External\XML\" + FileName;
            string fullPath = Directory.GetCurrentDirectory() + fullRelPath;

            if (!File.Exists(fullPath))
            {
                Validate.Fail(@"TestDataUploader could not find refrenced file at " + fullPath);
                return;
            }


            string xmlDataStr = "";
            XElement xmlEle;
            try
            {
                StreamReader reader = new StreamReader(fullPath);
                StringBuilder sb = new StringBuilder();

                while (!reader.EndOfStream)
                {
                    sb.AppendLine(reader.ReadLine());
                }
                reader.Close();
                reader = null;

                xmlDataStr = sb.ToString();
                sb = null;

                xmlEle = XElement.Parse(xmlDataStr);
            }
            catch (Exception e)
            {
                System.Diagnostics.Debug.WriteLine(@"There was an error accessing the XML data for TestDataUploader. " + e.Message);
                Validate.Fail(@"There was an error accessing the XML data for TestDataUploader. " + e.Message);
                return;
            }

            //Parse out the required paramaters.
            IEnumerable<XElement> keySegs =
                from seg in xmlEle.Descendants("Key")
                select (XElement)seg;

            if (!keySegs.Any())
            {
                System.Diagnostics.Debug.WriteLine(@"A valid Key element was not found when parsing XML data for TestDataUploader. Path is " + fullPath);
                Validate.Fail(@"A valid Key element was not found when parsing XML data for TestDataUploader. Path is " + fullPath);
                return;
            }

            //Now we should have a proper Key element with the parameters that we will need to write to the server.
            //Parse them out.
            XElement keyElement = keySegs.ElementAt(0);
            string errs = "";

            int moduleId = -1;
            Int32.TryParse(keyElement.Attribute("moduleID").Value, out moduleId);

            int clientId = -1;
            Int32.TryParse(keyElement.Attribute("clientID").Value, out clientId);

            string userName = keyElement.Attribute("loginName").Value;

            if (moduleId < 0)
                errs = errs + "\n No moudule ID was found!";

            if (clientId < 0)
                errs = errs + "\n No client ID was found!";

            if (userName == "")
                errs = errs + "\n No user name was found!";

            if (errs != "")
            {
                System.Diagnostics.Debug.WriteLine(@"Parameters in XML Data are missing or malformed! " + errs);
                Validate.Fail(@"Parameters in XML Data are missing or malformed! " + errs);
                return;
            }

            //If we got down to here it then we should have enough valid data to write to the server.
            //Make the request.
            HttpWebRequest webReq = (HttpWebRequest)WebRequest.Create("http://" + ServerProgramAddress);
            string postData = "mID=" + moduleId + "&cID=" + clientId + "&userName=" + userName + "&gameName=" + GameName + "&testData=" + xmlDataStr;
            byte[] postDataBytes = Encoding.UTF8.GetBytes(postData);

            webReq.Method = "POST";
            webReq.ContentType = "application/x-www-form-urlencoded";
            webReq.ContentLength = postDataBytes.Length;

            using (var stream = webReq.GetRequestStream())
            {
                stream.Write(postDataBytes, 0, postDataBytes.Length);
            }

            HttpWebResponse response = (HttpWebResponse)webReq.GetResponse();

            //Check for the Error types I manually set, fail if we hit those, warn on anything else besides ok.
            if (response.StatusCode == HttpStatusCode.BadRequest || response.StatusCode == HttpStatusCode.InternalServerError)
            {
                System.Diagnostics.Debug.WriteLine("TestDataUploader received an HTTP Error code: " + response.StatusCode);
                Validate.Fail("TestDataUploader received an HTTP Error code: " + response.StatusCode);
            }
            else if (response.StatusCode != HttpStatusCode.OK)
            {
                System.Diagnostics.Debug.WriteLine("TestDataUploader received an HTTP Error code that was not expected: " + response.StatusCode);
                Report.Warn("TestDataUploader received an HTTP Error code that was not expected: " + response.StatusCode);
            }
            else
            {
                Report.Info("TestDataUploader successfully added test data for user " + userName + ", module id is " + moduleId + ", and client id is " + clientId + ". The http status code was " + response.StatusCode);
            }
        }
    }
}
