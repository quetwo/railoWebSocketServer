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
  2. Edit the web.xml located in {rail-web}/WEB-INF/ to include the following lines :
    <listener>
        <listener-class>
            com.quetwo.wsRailoEndpoint.wsEndpointLoader
        </listener-class>
    </listener>
    
  3. Copy the files within the CFML directory in this project to their respective directories in your Railo server.  For example, /cfml/lib/railo-server/context/context/admin/gdriver/WebsocketWatcher.cfc will need to be copied to {railo-web}/lib/railo-server/context/context/admin/gdriver/WebsocketWatcher.cfc.   Yuu will need to do this for all 3 CFC files.
  4. The WebsocketWatcherListner.cfc file is the file that will contain your CFML logic.  Make a copy of this file and customize it to do what you want.  The default will log incoming messages to a log file, and will broadcast the incoming messages to the channel if it contains the word "echo".
  5. Restart Railo.  Once it has been restarted, you can add the new Event Gateway and start filtering channels.
  
