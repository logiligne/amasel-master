define('print/page_metrics', [ 'jquery','print/dimUnit' ], function($, DimUnit){
	var PageMetrics = function (parentId,configDict) {
		var div = $(parentId);
		div.css({
			position: 'relative'
		});

		this.canvas = $('<canvas></canvas>').appendTo(div)
			.css({
				top:0,
				left:0,
				position: "absolute"
			})
			.get(0);
    this.canvas.height = div.get(0).offsetHeight;
    this.canvas.width  = div.get(0).offsetWidth;

		this.c = this.canvas.getContext('2d');
		//
		
		this.s = $('<div></div>').appendTo(div);
		this.s.css({
			top:0,
			left:0,
			position: "absolute",
			width:"100%",
			height:"100%",
			"font-size" : "10px"
		});
		this.arrowSize = 5;
		this.configDict = configDict || {};
		
	}

	PageMetrics.canCreate = function(parentId){
		return $(parentId).length > 0;
	}
	
	PageMetrics.prototype.definePrintPage = function () {
		var cx=0, cy=0,
				cw = this.canvas.width,
				ch = this.canvas.height;
		var fw=90,
			 	fh=70,
				lw=200,
				lh=150;
				
		var boxes = {};
		boxes['pageWidth'] = {
			t:"hdim",
			x:cx , y: cy,
			w:cw-fw, h:fh,
			l: "Page width"
		}
		boxes['pageHeight'] = {
			t:"vdim",
			x:cw-fw , y: cy+fh,
			w:fw, h:ch-fh,
			l: "Page height"
		}
		cx += 0;
		cy += fh;
		cw -= fw;
		ch -= fh;
		boxes['paperPage'] = {
			t:"box",
			x:cx, y:cy,
			w:cw, h:ch,
			f: 'gray'
		}
			
		boxes['pageMarginTop'] = {
			t:"vdim",
			x:cx+fw, y:cy,
			w:cw-2*fw, h:fh,
			l: "Top margin"
		}
		boxes['pageMarginBottom'] = {
			t:"vdim",
			x:cx+fw, y:ch,
			w:cw-2*fw, h:fh,
			l: "Bottom margin"
		}
		boxes['pageMarginLeft'] = {
			t:"hdim",
			x:cx, y:cy+fh,
			w:fw, h:ch-2*fh,
			l: "Left margin"
		}
		boxes['pageMarginRight'] = {
			t:"hdim",
			x:cw-fw, y:cy+fh,
			w:fw, h:ch-2*fh,
			l: "Right margin"
		}
		cx += fw;
		cy += fh;
		cw -= 2*fw;
		ch -= 2*fh;

		boxes['printArea'] = {
			t:"box",
			x:cx, y:cy,
			w:cw, h:ch,
			f: 'white',
			l: "Page printable area"
		}

		this.objects = boxes;
	}

	PageMetrics.prototype.defineLabels = function () {
			
		var cx=0, cy=0,
				cw = this.canvas.width,
				ch = this.canvas.height;
		var fw=90,
			 	fh=70,
				lw=200,
				lh=150;
				
		var boxes = {};
		boxes['label'] = {
				t:"box",
				x:cx, y:cy,
				w:lw, h:lh,
				f: '#F0F8FF'
		}

		boxes['labelWidth'] = {
				t:"hdim",
				x:cx, y:cy,
				w:lw, h:fh,
				l: "Label width"
		}
		boxes['labelHeight'] = {
				t:"vdim",
				x:cx, y:cy,
				w:fw, h:lh,
				l: "Label height"
		}

		boxes['labelHNext'] = {
				t:"box",
				x:cx+lw+fw, y:cy,
				w:lw, h:lh,
				f: '#F0F8FF'
		}

		boxes['labelHorizontalSpacing'] = {
				t:"hdim",
				x:cx+lw, y:cy,
				w:fw, h:lh,
				l: "H Space"
		}

		boxes['labelVNext'] = {
				t:"box",
				x:cx, y:cy + lh + fh,
				w:lw, h:lh,
				f: '#F0F8FF',
		}

		boxes['labelVerticalSpacing'] = {
				t:"vdim",
				x:cx+lw/2, y:cy + lh,
				w:fw, h:fh,
				l: "V Space"
		}

		cx += 0;
		cy += 2*lh + fw;
		cw -= 0;
		ch -= 2*lh + fw;

		var blX = cx ,
				blY = cy + fw,
				blW = cw - 2*fw,
				blH = ch - 2*fh;
			
		boxes['bigLabel'] = {
			t:"box",
			x:blX, y:blY,
			w:blW, h:blH,
			f: 'gray'
		}

		boxes['labelMarginTop'] = {
			t:"vdim",
			x:blX +fw, y:blY,
			w:blW - 2*fw, h:fh,
			l: "Top inside label margin"
		}
		boxes['labelMarginBottom'] = {
			t:"vdim",
			x:blX+fw, y:blY + blH-fh,
			w:blW - 2*fw, h:fh,
			l: "Bottom inside label margin"
		}
		boxes['labelMarginLeft'] = {
			t:"hdim",
			x:blX, y:blY+fh,
			w:fw, h:blH-2*fh,
			l: "Left inside<br>label margin"
		}
		boxes['labelMarginRight'] = {
			t:"hdim",
			x:blX + blW - fw, y:blY+fh,
			w:fw, h:blH-2*fh,
			l: "Right inside<br>label margin"
		}

		boxes['labelContent'] = {
			t:"box",
			x:blX + fw, y:blY + fh,
			w:blW - 2*fw, h:blH - 2*fh,
			f: '#F0F8FF',
			l: "[Label content here]<br>Name...<br>Street...<br>Postcode<br>Country"
		}

		this.objects = boxes;
	}

		
	PageMetrics.prototype.drawObject = function (name) {
		var o = this.objects[name];
		if(o.t=="hdim"){
			  this.c.lineWidth   = 1;
				this.hArrow(o.x,o.x+o.w,o.y + o.h/2);
				this.c.beginPath();
				this.c.moveTo(o.x,o.y);
				this.c.lineTo(o.x,o.y+o.h);
				this.c.moveTo(o.x+o.w,o.y);
				this.c.lineTo(o.x+o.w,o.y+o.h);
				this.c.stroke();
		} else	if(o.t=="vdim"){
			  this.c.lineWidth   = 1;
				this.vArrow(o.x + o.w/2,o.y,o.y + o.h)
				this.c.beginPath();
				this.c.moveTo(o.x,o.y);
				this.c.lineTo(o.x+o.w,o.y);
				this.c.moveTo(o.x,o.y+o.h);
				this.c.lineTo(o.x+o.w,o.y+o.h);
				this.c.stroke();
		} else if(o.t == "box"){
			if(o.f){
				this.c.fillStyle = o.f;
				this.c.fillRect(o.x,o.y,o.w,o.h);
			}
			this.c.lineWidth   = 2;
			this.c.strokeRect(o.x,o.y,o.w,o.h);
		}
	}
		
	PageMetrics.prototype.setOption = function (name,value) {
		var val = $('#' + name).val();
		var v  = parseFloat( val );
		if(isNaN(v)){
			return false;
		}
		this.configDict[name] = new DimUnit(val).toString();
		return true;
	}
		
	PageMetrics.prototype.getOption = function (name) {
		return this.configDict[name];
	}
		
	PageMetrics.prototype.objSettings = function (name) {
		var o = this.objects[name];
		var e;
		if(o.t=="hdim" || o.t=="vdim"){
			e = $('<div style="display:inline;"></div>').css({
				'max-width' : (o.w-3) +'px',
				'max-height' : (o.h-3) +'px',
				'border': 'solid 1px grey',
				'background': '#b1e5a3',
				'padding' : '2px',
			}).append(
				$('<span id="' + name+'-label">'+ o.l +'</span><br>')
			).append(
				$('<input id="'+name+'" size="5" maxlength="10">').css({
					outline: 'none',
					border: 'none',
					'text-align': 'center',
					width: "50px"
				})
			);
						  
		} else {
			if(o.l){
				e = $('<div style="display:inline;">' +o.l+ '</div>').css({
					'max-width' : (o.w-3) +'px',
					'max-height' : (o.h-3) +'px',
					'padding' : '2px',
				});
		  }
		}
		if(!e){
			return
		}
		this.s.append(e);
		var w = e.width(),
			  h = e.height(),
				x = (o.w-w)/2,
				y = (o.h-h)/2;
				e.css({
					'position': 'absolute',
					'top': o.y + y,
					'left': o.x + x,
				});
		if( $('#' + name) ){
			if( $('#' + name).width() < $('#' + name +'-label').width() ){
				$('#' + name).width( $('#' + name +'-label').width() );
			}
			var self = this;
			$('#' + name).change(function(){
				if(!self.setOption(name, $('#' + name).val() )){
					// Show error
					alert("invalid");
				} else {
					$('#' + name).val( self.getOption(name) );
				}
			}).val(self.getOption(name));
		}
	}
		
	PageMetrics.prototype.draw = function (name) {
		for(var k in this.objects){
			this.drawObject(k);
		}
	}
		
	PageMetrics.prototype.buildSettings = function (name) {
		for(var k in this.objects){
			this.objSettings(k);
		}
	}
		
	PageMetrics.prototype.hArrow = function (sx,ex,y) {
		this.c.beginPath();
		this.c.moveTo(sx + this.arrowSize , y - this.arrowSize);
		this.c.lineTo(sx, y);
		this.c.lineTo(sx + this.arrowSize , y + this.arrowSize);
		this.c.moveTo(sx, y);
		this.c.lineTo(ex, y);

		this.c.moveTo(ex - this.arrowSize , y - this.arrowSize);
		this.c.lineTo(ex, y);
		this.c.lineTo(ex - this.arrowSize , y + this.arrowSize);
		this.c.stroke();
	}

	PageMetrics.prototype.vArrow = function (x,sy,ey) {
		this.c.beginPath();
		this.c.moveTo(x - this.arrowSize , sy + this.arrowSize);
		this.c.lineTo(x, sy);
		this.c.lineTo(x + this.arrowSize , sy + this.arrowSize);
		this.c.moveTo(x, sy);
		this.c.lineTo(x, ey);

		this.c.moveTo(x - this.arrowSize , ey - this.arrowSize);
		this.c.lineTo(x, ey);
		this.c.lineTo(x + this.arrowSize , ey - this.arrowSize);
		this.c.stroke();
	}
	return PageMetrics;
});