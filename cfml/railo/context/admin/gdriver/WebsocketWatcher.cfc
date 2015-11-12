<cfcomponent extends="Gateway">

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

    <cfset fields=array(
		field("Channel Name","channel","",true,"The channel you wish to interact with. Endpoint is ws://{server}/wsEndpoint/{channel}","text"))>

	<cffunction name="getClass" returntype="string">
    	<cfreturn "">
    </cffunction>
	<cffunction name="getCFCPath" returntype="string">
    	<cfreturn "railo.extension.gateway.WebsocketWatcher">
    </cffunction>
    
	<cffunction name="getLabel" returntype="string" output="no">
    	<cfreturn "WebSocket Driver">
    </cffunction>
	<cffunction name="getDescription" returntype="string" output="no">
    	<cfreturn "Interacts with a specific WebSocket channel on your server.">
    </cffunction>
    
	<cffunction name="onBeforeUpdate" returntype="void" output="false">
		<cfargument name="cfcPath" required="true" type="string">
		<cfargument name="startupMode" required="true" type="string">
		<cfargument name="custom" required="true" type="struct">
        <cfif len(custom.channel) EQ 0>
        	<cfthrow message="The channel name cannot be left blank.">
        </cfif>
	</cffunction>
    
    
	<cffunction name="getListenerCfcMode" returntype="string" output="no">
		<cfreturn "required">
	</cffunction>
	<cffunction name="getListenerPath" returntype="string" output="no">
		<cfreturn "railo.extension.gateway.WebsocketWatcherListener">
	</cffunction>
</cfcomponent>

