import { combineReducers, compose, createStore } from "redux";

import {
  Creators as KalevalaCreators,
  kalevalaMiddleware,
  promptReducer,
  socketReducer
} from "./kalevala";

import {
  Creators,
  channelReducer,
  eventsReducer,
  loginReducer
} from "./redux";

const composeEnhancers =
  typeof window === "object" && window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ ?
  window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__({}) : compose;

const eventTextHandlers = {
  "Channel.Broadcast": (dispatch, getState, event, { history }) => {
    const { channel_name, character, id, text } = event.data;
    dispatch(KalevalaCreators.socketReceivedEvent({ topic: "system/display", data: "\n" }, { history }));
    dispatch(Creators.channelBroadcast(channel_name, character, id, text));
  },
  "Character.Prompt": (dispatch, getState, event, { history }) => {
    const { text } = event;
    dispatch(KalevalaCreators.socketReceivedEvent({ topic: "system/display", data: text }, { history }));
  },
  "Character.Inventory": (dispatch, getState, event, { history }) => {
    const { text } = event;
    dispatch(KalevalaCreators.socketReceivedEvent({ topic: "system/display", data: text }, { history }));
  },
  "Login.Welcome": (dispatch, getState, event, { history }) => {
    dispatch(Creators.loginActive());
  },
  "Login.PromptCharacter": (dispatch, getState, event, { history }) => {
    history.push("/login/character");
  },
  "Login.EnterWorld": (dispatch, getState, event, { history }) => {
    const { text } = event;
    dispatch(KalevalaCreators.socketReceivedEvent({ topic: "system/display", data: text }, { history }));
    dispatch(Creators.loggedIn());

    history.push("/client");
  },
  "Room.CharacterEnter": (dispatch, getState, event, { history }) => {
    const { data, text } = event;
    dispatch(Creators.roomCharacterEntered(data.character));
    dispatch(KalevalaCreators.socketReceivedEvent({ topic: "system/display", data: text }, { history }));
  },
  "Room.CharacterLeave": (dispatch, getState, event, { history }) => {
    const { data, text } = event;
    dispatch(Creators.roomCharacterLeft(data.character));
    dispatch(KalevalaCreators.socketReceivedEvent({ topic: "system/display", data: text }, { history }));
  },
  "Room.Info": (dispatch, getState, event, { history }) => {
    const { text } = event;
    dispatch(KalevalaCreators.socketReceivedEvent({ topic: "system/display", data: text }, { history }));
  },
  "Room.Say": (dispatch, getState, event, { history }) => {
    const { text } = event;
    dispatch(KalevalaCreators.socketReceivedEvent({ topic: "system/display", data: text }, { history }));
  },
};

const systemEventHandlers = {
  "system/event-text": (dispatch, getState, event, args) => {
    const { topic, data, text } = event.data;

    let handler = eventTextHandlers[topic];

    if (handler) {
      handler(dispatch, getState, event.data, args);
    }

    dispatch(KalevalaCreators.socketReceivedEvent({ topic, data }, args));
  },
};

const middleware = compose(kalevalaMiddleware(systemEventHandlers), composeEnhancers());

const reducers = combineReducers({
  channel: channelReducer,
  login: loginReducer,
  prompt: promptReducer,
  socket: socketReducer,
  events: eventsReducer,
});

export const makeStore = () => {
  return createStore(reducers, middleware);
}
