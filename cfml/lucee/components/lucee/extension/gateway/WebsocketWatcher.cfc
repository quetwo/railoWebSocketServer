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

    <cfset state="stopped">
	
	<cffunction name="init" access="public" output="no" returntype="void">
		<cfargument name="id" required="false" type="string">
		<cfargument name="config" required="false" type="struct">
		<cfargument name="listener" required="false" type="component">
    	<cfset variables.id=id>
        <cfset variables.config=config>
        <cfset variables.listener=listener>

        <cflog text="Initilizing WebSocket interceptor for channel [#config.channel#]" type="information" file="WebsocketListner">
        <cfset variables.wsJavaDriver = createObject("java","com.quetwo.wsRailoEndpoint.wsEndpoint")>

	</cffunction>


	<cffunction name="start" access="public" output="no" returntype="void">
		<!-- for restart situations --->
        <cfwhile state EQ "stopping">
        	<cfset sleep(10)>
        </cfwhile>
        <cfset variables.state="running">

        <cfset variables.wsJavaDriver.watchChannel(config.channel)>

        <cflog text="Starting Websocket interceptor for channel [#config.channel#]" type="information" file="WebsocketListner">
		
        <cfwhile variables.state EQ "running">
            <!--- Loop while the WebSocket Watcher is running --->
            <cfset myIncomingMessages = variables.wsJavaDriver.getChannelQueue(config.channel)>
            <cfloop index="incomingMessage" array="#myIncomingMessages#">
                <cfset incomingMessage.gatewayID = variables.id>
                <cfset returnValue = variables.listener["onIncomingMessage"](incomingMessage)>
                <cfif isDefined("returnValue") && isStruct(returnValue)>
                    <cfset sendMessage(returnValue)>
                </cfif>
            </cfloop>
            <cfset sleep(10)>
    	</cfwhile>

        <cfset variables.wsJavaDriver.unwatchChannel(config.channel)>
        <cfset variables.state="stopped">
        
	</cffunction>
    
	<cffunction name="stop" access="public" output="no" returntype="void">
    	<cflog text="Stopping WebSocket inteceptor for channel [#config.channel#]" type="information" file="WebsocketListner">
		<cfset variables.state="stopping">
	</cffunction>

	<cffunction name="restart" access="public" output="no" returntype="void">
		<cfif state EQ "running"><cfset stop()></cfif>
        <cfset start()>
	</cffunction>

	<cffunction name="getState" access="public" output="no" returntype="string">
		<cfreturn state>
	</cffunction>

	<cffunction name="sendMessage" access="public" output="no" returntype="string">
		<cfargument name="data" required="false" type="struct">
		<!---  data should have the following structure :
                  data /
                          message   -- String encoded value of what you want to send
                          type      -- can be "MESSAGE", "DIRECTED", "ALL".  Defaults to MESSAGE.
                          sessionID -- If type is "DIRECTED" then the sessionID of the webSocket user to direct message to
                          channel   -- If type is "MESSAGE" then the channel name you want to send to.  Defaults to current
                                       gateway channel.
                                                                                                                 --->

        <cfif NOT isDefined("data.message")>
            <cfreturn "Unexpected Payload.  Please send a STRUCT with [MESSAGE,TYPE] nodes.">
        </cfif>
        <cfif NOT isDefined("data.type")>
            <cfset data.type = "MESSAGE">
        </cfif>
        <cfif NOT isDefined("data.channel")>
            <cfset data.channel = variables.config.channel>
        </cfif>
        <cfif NOT isDefined("data.sessionID")>
            <cfset data.sessionID = -1>
        </cfif>

        <cfswitch expression="#UCase(data.type)#">
            <cfcase value="MESSAGE">
                <cfset variables.wsJavaDriver.sendMessage(data.message, data.channel)>
            </cfcase>
            <cfcase value="DIRECTED">
                <cfset variables.wsJavaDriver.sendDirectedMessage(data.message, data.sessionID)>
            </cfcase>
            <cfcase value="ALL">
                <cfset variables.wsJavaDriver.sendMessage(data.message)>
            </cfcase>
        </cfswitch>

	</cffunction>

</cfcomponent>