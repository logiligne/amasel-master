define ( 'print/dimUnit', [], function() {
	var DimUnit = function (value, defaultUnits, allowedUnits){
	  if( value.v && value.u ){
	    this.v = value.v
	    this.u = value.u
	    return;
    }
		this.v = parseFloat(value);
		this.u = defaultUnits || DimUnit.defaultUnits || 'mm';
		if(!isNaN(this.v) && typeof value === 'string'){
			var allowed = allowedUnits || DimUnit.allowedUnits || ['mm'];
			for(var i =0 ; i <  allowed.length; ++i){
				var a = allowed[i];
				if( value.indexOf(a, value.length - a.length) !== -1) {
					this.u=a;
					break;
				}
			}
		}
	}

	DimUnit.setDefaults = function(defaultUnits, allowedUnits){
		DimUnit.defaultUnits = defaultUnits;
		DimUnit.allowedUnits = allowedUnits;
	}

	DimUnit.prototype.copy = function() {
		return new DimUnit(this.v,this.u);
	}

	DimUnit.prototype.getValue = function() {
		return this.v;
	}

	DimUnit.prototype.getUnits = function() {
		return this.u;
	}

	DimUnit.prototype.convert = function(to) {
		var newVal = this.v;
		var v = this.v;
		if(this.u == 'in') {
			if(to == 'mm'){
				newVal = v * 25.4;
			} else if( to== 'cm') {
				newVal = v * 2.54;
			} else if( to == 'pt') {
				newVal = v * 72;
			}
		} else if(this.u == 'mm' || this.u == 'cm'){
			if(this.u == 'cm') {
				v = v * 10;
				newVal = v;
			}
			//v is mm now
			if(to == 'in'){
				newVal = v * 0.0393701;
			}
			if( to == 'cm'){
				newVal = v / 10;
			}
			if( to == 'pt') {
				newVal = v / (25.4 / 72);
			}
		} else if(this.u == 'pt'){
			if(to == 'in'){
				newVal = v / 72;
			}
			if(to == 'mm'){
				newVal = v * ( 25.4 / 72);
			}
			if(to == 'cm') {
				newVal = v * ( 2.54 / 72);
			}
		}
		return new DimUnit(newVal,to?to:this.u,[]);
	}

	DimUnit.prototype.to = function(toUnit) {
		return this.convert(toUnit);
	}
	
	DimUnit.prototype['toMm'] = function(){
		return this.convert('mm');
	};
	DimUnit.prototype['toCm'] = function(){
		return this.convert('cm');
	};
	DimUnit.prototype['toIn'] = function(){
		return this.convert('in');
	};
	DimUnit.prototype['toPt'] = function(){
		return this.convert('pt');
	};

	DimUnit.prototype.add = function(other) {
	  if(typeof other == 'string') {
	    other = new DimUnit(other)
	  }
		var ou = other.convert(this.u);
		this.v += ou.v;
		return this;
	}

	DimUnit.prototype.sub = function(other) {
	  if(typeof other == 'string') {
	    other = new DimUnit(other)
	  }
		var ou = other.convert(this.u);
		this.v -= ou.v;
		return this;
	}

	DimUnit.prototype.toString = function() {
		return "" + this.v + this.u;
	}

	return DimUnit;
});
