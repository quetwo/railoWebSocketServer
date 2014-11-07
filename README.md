Railo WebSocket Server
====================

WebSocket engine for the Railo CFML engine.  Tunnels connections over existing HTTP, so you don't need to open additional firewall or application ports.

Requirements:
-------------
  1. JSR-356 compatible Java servlet engine, such as Apache Tomcat 1.7/1.8 or Glassflish
  2. Railo CFML Engine 4.2 or later
  
How it works:
-------------
When installed, a servlet engine will automatically start with Railo.  This engine will intercept any calls to http://{server}:{port}/{context}/wsEndpoint/.  Without any additional configuration, the WebSocket server will automatically echo messages to the engine to all other clients connected to that channel.  The channel you subscribe to is anything after the /wsEndpoint/.  For example, if you are running a server on localhost, you can connect to the "myChatRoom" channel by connecting your websocket client to ws://localhost/wsEndpoint/myChatRoom .  

You have the ability to intercept incoming messages and parse them with CFML by creating an Event Gateway within Railo and specifying the channel name you wish to intercept.  A CFML function is called with the incoming message, which you can then choose to echo out to the channel, or do something with.   You can also send WebSocket messages via the sendGatewayMessage() function to any channel defined by an EventGateway.

How to install:
---------------
  1. Copy the wsRailoEndpoint.jar file to the {railo-web}/WEB-INF/lib directory, or any other location in the Java Classpath.     
  2. Copy the files within the CFML directory in this project to their respective directories in your Railo server.  For example, /cfml/lib/railo-server/context/context/admin/gdriver/WebsocketWatcher.cfc will need to be copied to {railo-web}/lib/railo-server/context/context/admin/gdriver/WebsocketWatcher.cfc.   Yuu will need to do this for all 3 CFC files.
  3. The WebsocketWatcherListner.cfc file is the file that will contain your CFML logic.  Make a copy of this file and customize it to do what you want.  The default will log incoming messages to a log file, and will broadcast the incoming messages to the channel if it contains the word "echo". 
  4. Edit the web.xml located in {rail-web}/WEB-INF/ to include the following lines :
  
```  
  <listener>
    <listener-class>
      com.quetwo.wsRailoEndpoint.wsEndpointLoader
    </listener-class>
  </listener>
```  
  
Restart Railo.  Once it has been restarted, you can add the new Event Gateway and start filtering channels.
  
How to use:
-----------

 * Install, following the above instructions.  We expect this to become a Railo Extension Application soon.
 * Connect your HTML5 application to the new WebSocket server.  This would be within your application's Java context + /wsEndpoint/ + channel name.  For example, for a server answering requests on http://www.myWebsite.com, and you want to join the channel "myChatroom", you would use the address of ws://www.mywebsite.com/wsEndpoint/myChatroom .   If you connect to your Railo web site on http://172.16.32.100:8888/railo/   then you would connect to ws://172.16.32.100:8888/railo/wsEndpoint/myChatroom .
 * If a new websocket client connects to your server and the channel has never been used before, it is automatically created.  The default setting for a channel is to echo anything it gets to all the connected clients within that channel.
 * If you want to control a channel from with your CFML code, you need to create a new event gateway.  Copy the *WebsocketWatcherListner.cfc* (located in \WEB-INF\railo\components\railo\extension\gateway) with a new name, and edit it to include whatever logic you want.
    * Within this file, you *MUST* have a function named "onIncomingMessage" that accepts one argument of "ANY" type.
    * The incoming argument will be a structure that is :
                  
                     .messageType  (String)   Type of message. Can be MESSAGE, CONNECT, DISCONNECT
                     .message      (String)   String that was sent via the WebSocket connection from the client
                     .channel      (String)   Channel which contained the message.
                     .sessionID    (String)   The SessionID of the connection that sent the message.
                     .gatewayID    (String)   The ID of the event gateway that triggered the event.
   
    * If you want to send a message out, simply return a new structure in the format that the sendGatewayMessage expects (as explained below).
    * You will get a message for each client connecting, disconnecting and message sent to the channel you subscribed to.  The messageType node in the incoming data will tell you what type of packet it is.
    * The message property will be populated for only messageTypes of "MESSAGE".
    * The channel will contain the name of the channel that the gateway was subscribed to, and where the action happened.
    * The sessionID will contain the "sessionID" of the user connecting.  This is generated by the websocket server and is not a predictable number or string.
    * the gatewayID is the ID (name) of the event gateway that called you.
    * NOTE:  The Listener may not be scoped within your application.  You can not expect it to fall within your application.cfc/cfm.   
 * If you want to send a message to connected users, you can use Railo's *sendGatewayMessage()* function.
    * The function expects two properties:  the gatewayID (gateway name) as defined on the Event Gateway form in the admin, and a structure that defines how the message will be sent out.
    * The structure is as follows :
    
                     .type         (String)   Type of message. Can be MESSAGE, ALL, DIRECTED
                     .message      (String)   String that you are sending back.
                     .channel      (String)   (Optional)  The channel name that you want to send the message to.
                     .sessionID    (String)   If the message type is DIRECTED, the SessionID of the client you are sending
                                              the message to.  Otherwise ignored.

   * For type, you need to set either MESSAGE, ALL or DIRECTED.
     * MESSAGE = A normal message, sent to subscribers of the channel.
     * DIRECTED = A message that only the client with sessionID will get.  This is useful to send replies to requests.
     * ALL = The message will be sent to ALL users connected to this WebSocket Server.
   * Channel only needs to be defined if you wish to change the channel that you are sending the message to.  By default, it will send out the message to the channel defined by the Event Gateway.
   * SessionID only needs to be defined if you are sending a DIRECTED message.
   * An example way to send a message to all the websocket clients connected to the "msu-spartans" channel (where the event gateway name is "msu") :
   
        <cfset wsMessage = structNew()>
        <cfset wsMessage.type="MESSAGE">
        <cfset wsMessage.channel="msu-spartans">
        <cfset wsMessage.message="Go Green! Go White!">
        <cfset sendGatewayMessage("msu",wsMessage)>
   
   * The above code can be called from anywhere within your application.
 * Coding your JS application:  You are free to use any JS library that connects to websockets.  Additionally, you can use pretty much any Flash-based fall-back client (as long as it does not require the use of a socket-policy-server).  
      
Testing your installation:
--------------------------
 * You can test your install before writing your HTML5 code by going to [websockets.org](http://www.websocket.org/echo.html) and using their HTML5 client.  
