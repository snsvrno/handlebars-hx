package handlebars;

class Context {
	/*** the root object */
	private var root : Dynamic;
	/*** the current path of the context. */
	public var path : Array<String> = [];
	/*** the current context object */
	public var value : Dynamic;

	public function new(object : Dynamic) {
		root = object;
		value = root;
	}

	public function get(path : Array<String>, ?fromRoot : Bool = false) : Dynamic {
		var working = if (fromRoot) root else value;
		
		// equivalent to a "this"
		if (path.length == 0) return working;

		// sets the local context.
		for (i in 0 ... path.length - 1) {
			if (path[i] == "../") 
				working = getParent();
			else if (Reflect.hasField(working, path[i]))
				working = Reflect.getProperty(working, path[i]);
			else
				trace('unhandled error! $path');
		}

		if (Reflect.hasField(working, path[path.length-1]))
			return Reflect.getProperty(working, path[path.length-1]);
		else {
			trace('unhandled error! $path');
			return null;
		}
	}

	public function set(path : Array<String>, ?fromRoot : Bool = false) {
		// if we are setting from root we don't care about the current path at all.
		if (fromRoot) {
			// clean the path.
			while(this.path.length > 0) this.path.pop();
			// rest our local root.
			value = root;
		}

		for (i in 0 ... path.length) {
			this.path.push(path[i]);
			if (Reflect.hasField(value, path[i]))
				value = Reflect.getProperty(value, path[i]);
			else trace('unimplemented error $path');
		}

	}

	/**
	 * a special set that iterates through the scope, assuming its an array..
	 */
	public function forEach(path : Array<String>, callback : () -> Void) {
		var array : Array<Dynamic> = try { cast(get(path), Array<Dynamic>); }
		catch (e) { trace('array error: $path'); []; }
		set(path);
		var oldValue = value;
		for (a in array) {
			value = a;
			callback();
		}
		value = oldValue;
		unset(path);
	}

	public function unset(path : Array<String>) {
		var i = path.length - 1;

		// adjusts the current path to what we want it to be.
		while(i >= 0) {
			if (path[i] == this.path[this.path.length-1])
				this.path.pop();
			else throw 'error with path';
			i -= 1;
		}

		// sets the context
		set(this.path, true);
	}

	private function getParent() : Null<Dynamic> {
		if (path.length == 0) return null;
		else {
			var parentPath = [ for (i in 0 ... path.length-1) path[i] ];	
			return get(parentPath, true);
		}
	}
}

