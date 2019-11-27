(function() {
  var SKIP_PROPS;

  SKIP_PROPS = {
    __super__: true,
    constructor: true
  };

  Function.prototype.include = function(mixin) {
    var funct, methodName;
    if (!mixin) {
      throw 'Supplied mixin was not found';
    }
    if (typeof mixin === 'function') {
      mixin = mixin.prototype;
    }
    for (methodName in mixin) {
      funct = mixin[methodName];
      if (!SKIP_PROPS[methodName]) {
        if (!this.prototype.hasOwnProperty(methodName)) {
          this.prototype[methodName] = funct;
        }
      }
    }
    return this;
  };

}).call(this);
