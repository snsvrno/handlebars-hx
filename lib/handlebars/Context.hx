package handlebars;

class Context {
	
	private final root : Dynamic;
	private var context : Dynamic;
	private var path : Array<Path> = [ ];

	public function new(object : Dynamic) {
		root = object;
		context = root;
	}

	public function get(path : Array<Path>, ?fromRoot : Bool = false) : Null<Dynamic> {
		var working : Dynamic = if (fromRoot) root else context;

		if (path.length == 0) return working;

		// getting working to the level we want
		for (i in 0 ... path.length) {
			switch(path[i]) {
				case String(text):
					working = getField(working, text);

				case Parent: 
					working = getParent();

				case Current:
					// working = working;

				case Index(index): 
					var array = try { cast(working, Array<Dynamic>); }
					catch (e) { throw 'can only use an index if this is an array: $e'; }

					if (index >= array.length) throw 'cannot index value $index since array is only ${array.length} long.';
					
					working = array[index];
			}
		}

		return working;

		/*
		// getting the final value.
		switch(path[path.length-1]) {
			case String(text):
				return getField(working, text);

			case Parent: throw 'unimplemented';

			case Index(i):
				var array = try { cast(working, Array<Dynamic>); }
				catch (e) { throw 'can only use an index if this is an array: $e'; }

				if (i >= array.length) throw 'cannot index value $i since array is only ${array.length} long.';

									 // throw 'unimplemented';
		}*/
	}

	public function set(path : Array<Path>, ?fromRoot : Bool = false) {
		if (fromRoot) { 
			context = root;
			while(this.path.length > 0) this.path.pop();
		}

		for (p in path) {
			this.path.push(p);
			switch(p) {
				case String(text):
					context = getField(context, text);
				
				case Current:
					// context = context;
				
				case Parent:
					context = getParent();

				case Index(i):
					var array = try { cast(context, Array<Dynamic>); }
					catch (e) { throw 'not an array, cannot set index'; }

					if (i < array.length) context = array[i];
					else throw 'cannot set ${this.path} to index $i, only has length of ${array.length}';
			}

			if (context == null) throw 'no such context: $path at $p';
		}
	}

	/**
	 * move backwards in context per the given path.
	 * will check and confirm that this is the correct
	 * path before unsetting. will error if not valid
	 */
	public function unset(path : Array<Path>) {
		var i = path.length;
		while((i-=1) >= 0) switch([this.path[this.path.length-1], path[i]]) {

			case [String(a), String(b)] if (a == b): this.path.pop();

			case [Index(i), Index(j)] if (i == j): this.path.pop();

			default: throw 'invalid path provided to unset: $path';
		}

		set(this.path.copy(), true);
	}

	public function forEach(path : Array<Path>, callback : () -> Void) {
		// setting the scope
		set(path);

		var array : Array<Dynamic> = try { cast(context, Array<Dynamic>); }
		catch(e) { throw '$path is not an array! cannot use #each'; }

		for (i in 0 ... array.length) {
			var apath : Array<Path> = [Index(i)];
			set(apath);
			callback();
			unset(apath);
		}

		// clearing the scope
		unset(path);
	}

	/**
	 * gets the parent of the current context
	 */
	private function getParent(?offset : Int = 0) : Null<Dynamic> {
		if (this.path.length <= offset) return null;
		else switch(this.path[this.path.length - 1 - offset]) {
			case Parent: throw 'unimplemented';
			case Current: throw 'unimplemented';
			case Index(i): return getParent(offset + 1);	
			case String(text):
				var parentPath = [ for (i in 0 ... this.path.length - offset - 1) this.path[i]];
				return get(parentPath, true);
		}
	}

	inline private static function getField(object : Dynamic, field : String) : Null<Dynamic> {
		if (Reflect.hasField(object, field))
			return Reflect.getProperty(object, field);
		else {
			return null;
		}
	}
}
