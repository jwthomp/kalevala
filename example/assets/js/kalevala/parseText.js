const arrayWrap = (data) => {
  if(!(data instanceof Array)){
    data = [data];
  }

  return data;
};

const generateLineId = () => {
  return Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
};

class Line {
  constructor(text) {
    this.id = generateLineId();
    this.children = arrayWrap(text);
  }
}

const LineBreak = {};

const splitString = (string) => {
  let strings = string.split("\n").map(s => [LineBreak, s]).flat().slice(1);

  let reducer = (context, string) => {
    if (string === LineBreak) {
      context.strings = context.strings.concat([context.current, LineBreak]);
      context.current = [];
    } else {
      context.current.push(string);
    }

    return context;
  };

  let context = strings.reduce(reducer, {strings: [], current: []});

  context.strings = context.strings.concat([context.current]);

  return context.strings;
}

const flattenChildren = (children) => {
  let reducer = (context, child) => {
    if (child === LineBreak) {
      context.children = context.children.concat([context.current, LineBreak]);
      context.current = [];
    } else {
      context.current = context.current.concat(arrayWrap(child));
    }

    return context;
  };

  let context = children.reduce(reducer, {children: [], current: []});
  return context.children.concat([context.current]);
};

const parseTag = (tag) => {
  if (typeof tag === "string") {
    return splitString(tag);
  };

  if (tag instanceof Array) {
    return tag.map(parseTag).flat();
  }

  let children = tag.children.map(parseTag).flat();

  return flattenChildren(children).map((children) => {
    if (children === LineBreak) {
      return LineBreak;
    }

    return { ...tag, children: arrayWrap(children) };
  });
};

const parseText = (input) => {
  let children = arrayWrap(input).map(parseTag).flat();

  return flattenChildren(children).filter((tag) => {
    return tag != LineBreak;
  }).map((tag) => {
    return new Line(tag);
  });;
};

export default parseText;
export { Line, LineBreak, parseTag };
