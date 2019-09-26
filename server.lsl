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

getHandler(list path, list args, string body)
{
   llOwnerSay("path: " + llList2CSV(path));
   llOwnerSay("args: " + llList2CSV(args));
   llOwnerSay("body: " + body);
}



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
         llOwnerSay("NEW REQUEST: "+llList2CSV([id,method,body]));
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
         
         // Split up any path information into path segments
         list path = llParseString2List(llGetHTTPHeader(id,"x-path-info"),["/"],[]);
         // Split up the query args into a usable list
         // If you use ?, =, + or & in keys or values then you may need to adjust this.
         string query_arg = llGetHTTPHeader(id,"x-query-string");
         query_arg = llUnescapeURL(query_arg);
         list query_args = llParseString2List(query_arg,["?","=","+","&"],[]);

         llOwnerSay("method: "+method);   
         if (method == "GET")
         {
            llSetContentType(id, CONTENT_TYPE_TEXT);
            llHTTPResponse(id, 200, "OK");
            getHandler(path,query_args,body);
         }
         else if (method == "POST")
         {
            llSetContentType(id, CONTENT_TYPE_TEXT);
            llHTTPResponse(id, 200, "OK");
            getHandler(path,query_args,body);
         }
         else
         {
            llHTTPResponse(id,405,"Unsupported Method");
         }
      }
       

   } // http_request
}    
