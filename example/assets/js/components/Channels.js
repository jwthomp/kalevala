import React from "react";
import { connect } from 'react-redux';

import { getChannelMessages } from "../redux";

const Message = ({ channelName, character, id, text }) => {
  return (
    <span className="block bg-white rounded p-4 m-2">
      <div className="block">
        <span className="text-gray-600">[{channelName}]</span> <span className="text-yellow-700">{character.name}</span> says,
      </div>
      <span className="text-green-600">{text}</span>
    </span>
  );
};

class Channels extends React.Component {
  constructor(props) {
    super(props);

    this.triggerScroll = true;
  }

  componentDidMount() {
    this.scrollToBottom();
  }

  componentDidUpdate() {
    this.scrollToBottom();
  }

  getSnapshotBeforeUpdate() {
    let visibleBottom = this.messages.scrollTop + this.messages.clientHeight;
    this.triggerScroll = !(visibleBottom + 250 < this.messages.scrollHeight);

    return null;
  }

  scrollToBottom() {
    if (this.triggerScroll) {
      this.el.scrollIntoView();
    }
  }

  render() {
    const { messages } = this.props;

    return (
      <div className="flex flex-col h-full">
        <h3 className="text-xl p-4">Communications</h3>
        <div className="flex-grow overflow-y-scroll" ref={el => { this.messages = el; }}>
          {messages.map(({ channelName, character, id, text }) => {
            return (
              <Message key={id} channelName={channelName} character={character} text={text} />
            );
          })}
          <div ref={el => { this.el = el; }} />
        </div>
      </div>
    );
  }
};

let mapStateToProps = (state) => {
  const messages = getChannelMessages(state);

  return { messages };
};

Channels = connect(mapStateToProps)(Channels);

export { Channels };
