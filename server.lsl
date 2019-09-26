/*
   OnTrack  by Tracer Prometheus aka Tracert Ping
   An experiment in communications between the real world and the virtual one
     
   Notes:
      URLs are automatically released and invalidated in certain situations. In the following situations, there is no need to call llReleaseURL. But you will have to request a new one afterwards
      When the region is restarted or goes offline
      When the script holding the URLs is reset, or recompiled
      When the object containing the script is deleted, or taken to inventory
      
*/


key url_request;

default
{
   state_entry()
   {
      url_request = llRequestURL();
   }

   touch_start(integer total_number)
   {
      llSay(0, "Touched.");
   }
    
   http_request(key id, string method, string body)
   {
      integer goodResponseStatus = 200;
      string goodResponseBody = "OK";
      integer badResponseStatus = 400;
      string badResponseBody = "Unsupported method"; 
      //llOwnerSay(llList2CSV([id,method,body]));
      if (url_request == id)
      {
         url_request = "";
         if (method == URL_REQUEST_GRANTED)
         {
            llOwnerSay("NEW URL: " + body);
         }
         else if (method == URL_REQUEST_DENIED)
         {             
            llOwnerSay("Something went wrong, no url:\n" + body);
         }
      }
      else
      {
         llOwnerSay(llList2CSV([id,method,body]));
         list headerList = ["x-script-url",
                            "x-path-info", "x-query-string",
                            "x-remote-ip", "user-agent",
                            "Content-Length","content-length",
                            "Host","host"];
 
         integer index = -llGetListLength(headerList);
         do
         {
            string header = llList2String(headerList, index);
            llOwnerSay(header+": "+llGetHTTPHeader(id, header));
         }
         while (++index);

         llOwnerSay("body:\n" + body);
         llSetContentType(id, CONTENT_TYPE_TEXT);
         llHTTPResponse(id, goodResponseStatus, goodResponseBody);
      }
       

   } // http_request
}    
