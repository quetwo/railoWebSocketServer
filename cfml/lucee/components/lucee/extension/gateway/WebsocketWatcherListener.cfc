<cfcomponent>
<!---
 Copyright 2014 -  Nick Kwiatkowski  (http://www.quetwo.com)

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
--->

    <!---
        The only function we really care about in this Listner is the onIncomingMessage (required).

        You will get a struct with the following items :
            data /
                 .messageType  (String)   Type of message. Can be MESSAGE, CONNECT, DISCONNECT
                 .message      (String)   String that was sent via the WebSocket connection from the client
                 .channel      (String)   Channel which contained the message.
                 .sessionID    (String)   The SessionID of the connection that sent the message.
                 .gatewayID    (String)   The ID of the event gateway that triggered the event.

        If you return a value from this function it will be sent back to the WebSocket.  You will need
        to create a new Struct in order to send the message back properly.  The returned struct should
        be in the format of :
            returnValue /
                 .type         (String)   Type of message. Can be MESSAGE, ALL, DIRECTED
                 .message      (String)   String that you are sending back.
                 .channel      (String)   (Optional)  The channel name that you want to send the message to.
                 .sessionID    (String)   If the message type is DIRECTED, the SessionID of the client you are sending
                                          the message to.  Otherwise ignored.

    --->

	<cffunction name="onIncomingMessage" access="public" output="no">
    	<cfargument name="data" type="any" required="yes">

        <cfif data.messageType EQ "MESSAGE">
            <cflog text="Incoming Message : #data.message#" type="information" file="WebsocketListner">
        <cfelse>
            <cflog text="Control Message : #data.messageType# on Session #data.sessionID#" type="information" file="WebsocketListner">
        </cfif>

        <!--- if the incoming message had "echo" in it, then echo it back to the channel --->
        <cfif data.message.contains("echo")>
            <cfset returnValue = structNew()>
            <cfset returnValue.type = "MESSAGE">
            <cfset returnValue.message = data.message>
            <cfreturn returnValue>
        </cfif>

        <!--- otherwise we just do nothing with it.  --->
	</cffunction>

</cfcomponent>