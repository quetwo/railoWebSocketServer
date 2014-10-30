/**
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

 */

package com.quetwo.wsRailoEndpoint;

import javax.websocket.*;
import javax.websocket.server.ServerEndpoint;
import java.io.IOException;
import java.util.HashMap;
import java.util.HashSet;
import java.util.logging.Level;
import java.util.logging.Logger;

@ServerEndpoint("/wsEndpoint/{channel}")
public class wsEndpoint
{
    private static final Logger logger = Logger.getLogger(wsEndpoint.class.getName());

    // Shared Session Lists to send messages out
    private static final HashMap<String,HashSet<Session>> channelList = new HashMap<String, HashSet<Session>>();
    private static final HashSet<Session> allUsers = new HashSet<Session>();

    // Queued Messages for pickup
    private static final HashSet<String> watchedChannels = new HashSet<String>();
    private static final HashMap<String, HashSet<wsEndpointMessage>> queuedMessages = new HashMap<String, HashSet<wsEndpointMessage>>();

    public wsEndpoint()
    {
        logger.log(Level.FINE,"Creating new WebSocket endpoint connection at /wsEndpoint/{channel} ....");
    }

    @OnOpen
    public void onOpen(Session session, EndpointConfig endpointConfig)
    {
        String channel = session.getPathParameters().get("channel");
        logger.log(Level.FINER, "Accepted WebSocket Client [" + session.getId() + "] into channel " + channel + " via " + session.getRequestURI());

        if (!channelList.containsKey(channel))
        {
            // The channel didn't exist, so we need to create it and start tracking it.
            channelList.put(channel,new HashSet<Session>());
            logger.log(Level.FINER,"Created new WebSocket Channel " + channel);
        }
        channelList.get(channel).add(session);
        allUsers.add(session);

        if (watchedChannels.contains(channel))
        {
            // if this channel is being watched by Railo, then we need to let it know somebody connected.
            wsEndpointMessage messageInQueue = new wsEndpointMessage();
            messageInQueue.channel = channel;
            messageInQueue.message = "";
            messageInQueue.messageType = "CONNECT";
            messageInQueue.sessionID = session.getId();
            synchronized (this)
            {
                queuedMessages.get(channel).add(messageInQueue);
            }
        }

    }

    @OnClose
    public void onClose(Session session, CloseReason closeReason)
    {
        String channel = session.getPathParameters().get("channel");
        logger.log(Level.FINER,"Closed WebSocket Client [" + session.getId() + "]");

        channelList.get(channel).remove(session);
        if (channelList.get(channel).isEmpty())
        {
            // no more users in the channel.  unload it.
            channelList.remove(channel);
            logger.log(Level.FINER,"Destroyed WebSocket Channel " + channel + ".  No users remain.");
        }

        allUsers.remove(session);

        if (watchedChannels.contains(channel))
        {
            // if this channel is being watched by Railo, then we need to let it know somebody disconnected.
            wsEndpointMessage messageInQueue = new wsEndpointMessage();
            messageInQueue.channel = channel;
            messageInQueue.message = "";
            messageInQueue.messageType = "DISCONNECT";
            messageInQueue.sessionID = session.getId();
            synchronized (this)
            {
                queuedMessages.get(channel).add(messageInQueue);
            }
        }
    }

    @OnError
    public void onError(Session session, Throwable thr)
    {
        logger.log(Level.FINER,"WebSocket Client Error [" + session.getId() + "] -> " + thr.toString());
    }

    @OnMessage
    public void onMessage(String message, Session session)
    {
        String channel = session.getPathParameters().get("channel");
        logger.log(Level.FINER,"WebSocket Message [" + session.getId() + "] -> " + message);

        if (!watchedChannels.contains(channel))
        {
            for(Session channelUser : channelList.get(channel))
            {
                try
                {
                    channelUser.getBasicRemote().sendText(message);
                }
                catch (IOException e)
                {
                    e.printStackTrace();
                }
            }
        }
        else
        {
            // if this channel is being watched by Railo, then we need to forward the message for Railo to handle.
            wsEndpointMessage messageInQueue = new wsEndpointMessage();
            messageInQueue.channel = channel;
            messageInQueue.message = message;
            messageInQueue.messageType = "MESSAGE";
            messageInQueue.sessionID = session.getId();
            synchronized (this)
            {
                queuedMessages.get(channel).add(messageInQueue);
            }
        }


    }

    public void sendMessage(String message, String channel)
    {
        if (!channelList.containsKey(channel))
        {
            return;
        }
        for(Session channelUser : channelList.get(channel))
        {
            try
            {
                channelUser.getBasicRemote().sendText(message);
            }
            catch (IOException e)
            {
                e.printStackTrace();
            }
        }
    }

    public void sendMessage(String message)
    {
        for(Session user : allUsers)
        {
            try
            {
                user.getBasicRemote().sendText(message);
            }
            catch (IOException e)
            {
                e.printStackTrace();
            }
        }
    }

    public void sendDirectedMessage(String message, String sessionID )
    {
        for(Session user : allUsers)
        {
            if (user.getId().equals(sessionID))
            {
                try
                {
                    user.getBasicRemote().sendText(message);
                }
                catch (IOException e)
                {
                    e.printStackTrace();
                }
            }
        }
    }

    public void watchChannel(String channel)
    {
        // Have Railo watch the channel instead of being a generic echo websocket.
        watchedChannels.add(channel);
        queuedMessages.put(channel, new HashSet<wsEndpointMessage>());
    }

    public synchronized void unwatchChannel(String channel)
    {
        // Return the channel back to echo.
        watchedChannels.remove(channel);
        queuedMessages.remove(channel);
    }

    public HashSet<wsEndpointMessage> getChannelQueue(String channel)
    {
        HashSet<wsEndpointMessage> queueReturn;
        if(!watchedChannels.contains(channel))
        {
             queueReturn = new HashSet<wsEndpointMessage>();
            return queueReturn;
        }
        synchronized (this)
        {
            queueReturn = new HashSet<wsEndpointMessage>(queuedMessages.get(channel));
            queuedMessages.get(channel).clear();

        }
        return queueReturn;
    }

}
