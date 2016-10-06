﻿class Graph {
	private var x_max:Number;
	private var x_min:Number;
	private var y_max:Number;
	private var y_min:Number;
	private var num_points_x:Number;
	private var num_points_y:Number;
	private var zoom:Number;
	private var increment_x:Number;
	private var increment_y:Number;
	private var origin_x:Number;
	private var origin_y:Number;
	private var rotate_x:Number;
	private var rotate_y:Number;
	private var sin_x:Number;
	private var cos_x:Number;
	private var sin_y:Number;
	private var cos_y:Number;
	private var points:Array;
	private var trans:Number = Math.PI/180;
	//
	// graph object -- draws a new graph
	// PARAMETERS
	// equation - a function reference that returns a value when passed two others ("x" and "y")
	// x_max, x_min, y_max, y_min - dimensions of the window for the graph
	// num_points_x, num_points_y - number of points to be plotted along the x- and y-axis
	// zoom - a ratio of how much to zoom in ... adjusting this makes graphs easier to view
	// rotate_x, rotate_y - orientation of graph
	// center_x, center_y - the origin as it should appear on Flash's Stage
	function Graph(x_max:Number, x_min:Number, y_max:Number, y_min:Number, num_points_x:Number, num_points_y:Number, zoom:Number, rotate_x:Number, rotate_y:Number, origin_x:Number, origin_y:Number) {
		// rectangular region that surface will be drawn over (domain) -- D = {(x, y) | x_min < x < x_max, y_min < y < y_max}
		this.x_max = x_max;
		this.x_min = x_min;
		this.y_max = y_max;
		this.y_min = y_min;
		// number of points to be placed along the x- and y-axis
		this.num_points_x = num_points_x;
		this.num_points_y = num_points_y;
		// zoom ratio
		this.zoom = zoom;
		// increments to go along the x- and y-axis
		this.increment_x = (this.x_max-this.x_min)/this.num_points_x;
		this.increment_y = (this.y_max-this.y_min)/this.num_points_y;
		// position of the origin
		this.origin_x = origin_x;
		this.origin_y = origin_y;
		// orientation of graph on the x- and y-axis
		this.rotate_x = rotate_x;
		this.rotate_y = rotate_y;
		// sine and cosine of rotation angles
		sin_x = Math.sin(this.rotate_x*trans);
		cos_x = Math.cos(this.rotate_x*trans);
		sin_y = Math.sin(this.rotate_y*trans);
		cos_y = Math.cos(this.rotate_y*trans);
	}
	//
	// stretches "mc" to connect point (x1, y1) and (x2, y2) -- "mc" should be the full path to the movie clip
	private function draw_line(mc:MovieClip, x1:Number, y1:Number, x2:Number, y2:Number) {
		mc._x = x1;
		mc._y = y1;
		mc._xscale = x2-x1;
		mc._yscale = y2-y1;
	}
	//
	// multivariable function that depend on both "x" and "y" --- mess with the return value to render different surfaces
	// NOTE: when using trigonometric functions, multiply the expression within the parentheses by "trans" to change degrees into radians
	private function function_xy(x:Number, y:Number) {
		return (4*Math.sin((x*y-x*x+y*y)*trans));
	}
	//
	// plots a 3d surface z = f(x, y)
	public function plot() {
		// get the position of the points on the surface
		calculate_points();
		// connect all the points with lines -- to create the grid
		draw_grid();
	}
	//
	// connects all the points with lines to create the grid
	private function draw_grid() {
		// the position of the two points a line will connect
		var x1:Number;
		var y1:Number;
		var x2:Number;
		var y2:Number;
		//
		_root.clear();
		_root.lineStyle(1, 0x00ff00, 100);
		// loop through and connect all the lines going vertical
		for (var j = 1; j<num_points_x+1; j++) {
			for (var k = 0; k<=num_points_y; k++) {
				// find the two points the line is to connect
				x1 = points[j][k].perspective_x;
				y1 = points[j][k].perspective_y;
				x2 = points[j-1][k].perspective_x;
				y2 = points[j-1][k].perspective_y;
				// connect the two points with the line
				_root.moveTo(x1, y1);
				_root.lineTo(x2, y2);
			}
		}
		//
		// loop through and connect all the lines going horizontal
		for (var j = 0; j<=num_points_x; j++) {
			for (var k = 1; k<=num_points_y; k++) {
				// find the two points the line is to connect
				x1 = points[j][k].perspective_x;
				y1 = points[j][k].perspective_y;
				x2 = points[j][k-1].perspective_x;
				y2 = points[j][k-1].perspective_y;
				//
				// connect the two points with the line
				_root.moveTo(x1, y1);
				_root.lineTo(x2, y2);
			}
		}
	}
	//
	// calculates the position of the points to be rendered
	private function calculate_points() {
		// two dimensional array of objects that hold the position of every point
		points = new Array();
		//
		// loop through the x-values
		for (var j = 0; j<=num_points_x+1; j++) {
			// add another dimension to the array
			points[j] = new Array();
			// loop through the y-values
			for (var k = 0; k<=num_points_y; k++) {
				// create a new object in the array's element to keep track of the ordered triplet (x,y,z)
				points[j][k] = new Object();
				// calculate the ordered triplet
				points[j][k].x = index_to_coord("x", j);
				points[j][k].y = index_to_coord("y", k);
				points[j][k].z = function_xy(points[j][k].x, points[j][k].y);
				// change the point from Flash's coordinate system to a real math rectangular system
				exchange_point(j, k);
				// rotate the point around the x- and y-axis
				rotate_point(j, k);
				// zoom into graph
				scale_point(j, k);
				// add perspective to point
				perspective_point(j, k);
				// translate point to the origin
				translate_point(j, k);
			}
		}
	}
	// changes index values (j, k) of an array to coordinates (x, y) on the graph
	private function index_to_coord(determine:String, index:Number) {
		return (index*this["increment_"+determine]+this[determine+"_min"]);
	}
	//
	// changes the window of the graph
	public function change_window(x_max:Number, x_min:Number, y_max:Number, y_min:Number, z_max:Number, z_min:Number) {
		// update the window dimensions
		this.x_max = Number(x_max);
		this.x_min = Number(x_min);
		this.y_max = Number(y_max);
		this.y_min = Number(y_min);
		// update the increments along the x- and y-axis
		increment_x = (this.x_max-this.x_min)/num_points_x;
		increment_y = (this.y_max-this.y_min)/num_points_y;
	}
	// changes the number of points to be plotted along the x- and y-axis
	public function change_num_points(num_points_x:Number, num_points_y:Number) {
		// update the number of points to be placed along the x- and y-axis
		this.num_points_x = Number(num_points_x);
		this.num_points_y = Number(num_points_y);
		// update the increments along the x- and y-axis
		increment_x = (this.x_max-this.x_min)/this.num_points_x;
		increment_y = (this.y_max-this.y_min)/this.num_points_y;
	}
	//
	// changes the zoom ratio
	public function change_zoom(zoom:Number) {
		this.zoom = Number(zoom);
	}
	//
	// changes the rotation angles
	public function change_rotation(rotate_x:Number, rotate_y:Number) {
		this.rotate_x = Number(rotate_x);
		this.rotate_y = Number(rotate_y);
		// update the sine and cosine of the rotation angles
		calculate_sine_cosine();
	}
	//
	// changes a point from Flash's coordinate system to a real math rectangular system
	private function exchange_point(a:Number, b:Number) {
		// the ordered triplet of the point
		var x:Number;
		var y:Number;
		var z:Number;
		// get the ordered triplet
		x = points[a][b].x;
		y = points[a][b].y;
		z = points[a][b].z;
		// change from Flash's system to rectangular
		points[a][b].x = y;
		points[a][b].y = z;
		points[a][b].z = x;
	}
	//
	// rotates a point (passed as an Object) by "a" and "b" on the x- and y-axes
	private function rotate_point(a:Number, b:Number) {
		// ordered triplet to be rotated
		var x:Number;
		var y:Number;
		var z:Number;
		// temporary rotated coordinates
		var rx1:Number;
		var ry1:Number;
		var rz1:Number;
		var rx2:Number;
		var ry2:Number;
		var rz2:Number;
		// get ordered triplet
		x = points[a][b].x;
		y = points[a][b].y;
		z = points[a][b].z;
		// rotate point on y-axis
		rx1 = x*cos_y-z*sin_y;
		ry1 = y;
		rz1 = z*cos_y+x*sin_y;
		// rotate point on x-axis
		rx2 = rx1;
		ry2 = ry1*cos_x-rz1*sin_x;
		rz2 = rz1*cos_x+ry1*sin_x;
		// update the values in the position array
		points[a][b].x = rx2;
		points[a][b].y = ry2;
		points[a][b].z = rz2;
	}
	//
	// scales the graph -- appears to "zoom"
	private function scale_point(a:Number, b:Number) {
		points[a][b].x *= zoom;
		points[a][b].y *= zoom;
		points[a][b].z *= zoom;
	}
	//
	// changes an ordered triplet to an ordered pair
	private function perspective_point(a:Number, b:Number) {
		// used for perspective -- distance from the viewer's eye to the screen
		var D:Number = 500;
		// perspective ratio -- used for changing an ordered triplet to an ordered pair
		var perspective_ratio:Number;
		// if point is in front of view calculate position of screen
		if (points[a][b].z>-D) {
			// calculate the perspective ratio
			perspective_ratio = D/(points[a][b].z+D);
			// calculate the position of the point on the screen
			points[a][b].perspective_x = perspective_ratio*points[a][b].x;
			points[a][b].perspective_y = perspective_ratio*points[a][b].y;
		} else {
			// point is behind user so it should not be drawn
			points[a][b].perspective_x = null;
			points[a][b].perspective_y = null;
		}
	}
	//
	// translates the point to make the origin where the user specifies
	private function translate_point(a:Number, b:Number) {
		points[a][b].perspective_x = origin_x+points[a][b].perspective_x;
		points[a][b].perspective_y = origin_y-points[a][b].perspective_y;
	}
	//
	// calculates the sine and cosine of the rotation angles
	private function calculate_sine_cosine() {
		sin_x = Math.sin(rotate_x*trans);
		cos_x = Math.cos(rotate_x*trans);
		sin_y = Math.sin(rotate_y*trans);
		cos_y = Math.cos(rotate_y*trans);
	}
}
