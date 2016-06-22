/*
 * Created by Ranorex
 * User: PavloK
 * Date: 6/19/2016
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


namespace QA_Automation.Internal.Setup
{
    [TestModule("F7F5F456-2437-4A40-BAA6-B48B7BC32343", ModuleType.UserCode, 1)]
    class RestoreTestFiles : ITestModule
    {
        public RestoreTestFiles()
        {
            // Do not delete - a parameterless constructor is required!
        }

        string _ServerProgramAddress = "casinoas1/RestoreTestData.ashx";
        [TestVariable("4F1281E0-DD14-409A-881A-D63B4EE806B8")]
        public string ServerProgramAddress
        {
            get { return _ServerProgramAddress; }
            set { _ServerProgramAddress = value; }
        }

        //When inputing the XML file name, please include file extension. This allows for .xml or .textdata files.
        string _FileName = "NinjaMagic_12545_10003_dgc6.testdata";
        [TestVariable("124064B4-F955-40F4-8631-DAB30CFAQ92")]
        public string FileName
        {
            get { return _FileName; }
            set { _FileName = value; }
        }

        void ITestModule.Run()
        {

            //TODO: 
            HttpWebRequest webReq = (HttpWebRequest)WebRequest.Create("http://" + ServerProgramAddress);
            string postData = "FileName=" + FileName;
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
                Report.Info("TestDataUploader successfully added test data for user " + response.StatusCode);
            }
        }
    }
}
