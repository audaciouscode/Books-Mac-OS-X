
class net.aetherial.books.webexport.Gallery extends MovieClip
{
	public var one:MovieClip;
	public var two:MovieClip;
	public var three:MovieClip;
	public var four:MovieClip;
	public var five:MovieClip;
	public var six:MovieClip;
	public var seven:MovieClip;
	public var eight:MovieClip;

	public var refreshButton:MovieClip;

	public var searchQuery:TextField;
	
	public var coverArray:Array;
	public var coverPool:Array;
	
	public var next:MovieClip;
	public var previous:MovieClip;

	public var matches:Array;
	public var page:Number;
	
	private var xml:XML;
	
	public function onEnterFrame ()
	{
		var me = this;

		var keyListener:Object = new Object (); 

		keyListener.onKeyUp = function () 
		{ 
			if (Key.getCode () == Key.ENTER)
				me.search (me.searchQuery.text);
		} 
		
		Key.addListener (keyListener);

		refreshButton.onPress = function ()
		{
			me.onEnterFrame = me.loadCovers ();
		}

		coverArray = new Array ();

		coverArray.push (one);
		coverArray.push (two);
		coverArray.push (three);
		coverArray.push (four);
		coverArray.push (five);
		coverArray.push (six);
		coverArray.push (seven);
		coverArray.push (eight);
		
		for (var i = 0; i < coverArray.length; i++)
			coverArray[i]._visible = false;
		
		xml = new XML ();
		
		xml.onLoad = function (success:Boolean)
		{
			var export = this.firstChild;
			
			var books = export.childNodes;
			
			me.coverPool = new Array ();
				
			for (var i = 0; i < books.length; i++)
			{
				var book = books[i];

				if (book.nodeName == "Book")			
				{
					var hasCover = false;
					
					var fields = book.childNodes;
	
					var coverBook = new Object ();
			
					for (var j = 0; j < fields.length; j++)
					{
						var field = fields[j];

						if (field.attributes["name"] == "coverImage")
							hasCover = true;
						else if (field.attributes["name"] == "title" || field.attributes["name"] == "id")
							coverBook[field.attributes["name"]] = field.firstChild.nodeValue;
						else
							coverBook[field.attributes["name"]] = field.firstChild.nodeValue.toLowerCase ();
					}
				
					if (hasCover)
					{
						me.coverPool.push (coverBook);
					}
				}
			}

			var comp = function (a, b)
			{
				if (a.title < b.title)
					return -1;
				else if (a.title > b.title)
					return 1;
				else
					return 0;
			}
				
			me.coverPool.sort (comp);
			
			trace ("xml done");
				
			me.onEnterFrame = me.loadCovers;
		}

		xml.load ("books-export.xml");
		trace ("done");
		onEnterFrame = undefined;
	}
	
	public function search (query)
	{
		query = query.toLowerCase ();
		
		matches = new Array ();
		
		var fieldArray = new Array ("title", "summary", "authors", "illustrators", "editors", "translators", "publisher");

		for (var i = 0; i < coverPool.length; i++)
		{
			var book = coverPool[i];

			var contains = false;

			for (var j = 0; j < fieldArray.length; j++)
			{	
				var field = book[fieldArray[j]];
				
				if (fieldArray[j] == "title")
					field = field.toLowerCase ();
				
				if (field != undefined && field.indexOf (query) != -1 && !contains)
				{
					matches.push (i);
					
					contains = true;
				} 
			}
		}
		
		loadSearch (0);
	}

	public function loadSearch (pageNo)
	{
		page = pageNo;

		var me = this;
		
		if (page > 0)
		{
			previous._visible = true;
			
			previous.onPress = function ()
			{
				me.loadSearch (pageNo - 1);
			}
		}
		else
		{
			previous._visible = false;
		}

		for (var i = 0; i < coverArray.length; i++)
		{
			coverArray[i]._visible = false;
		}

		for (var i = pageNo * 8; i < matches.length && i < ((pageNo + 1) * 8); i++)
		{
			loadCover (i - (pageNo * 8), matches[i]);
		}
		
		if (matches.length > ((pageNo + 1) * 8))
		{
			next._visible = true;
			
			next.onPress = function ()
			{
				me.loadSearch (pageNo + 1);
			}
		}
		else
		{
			next._visible = false;
		}
	}
	
	public function loadCovers ()
	{
		var me = this;
	
		searchQuery.text = "";

		next._visible = false;
		previous._visible = false;

		var randomNumbers = new Array ();
				
		while (randomNumbers.length < 8 && randomNumbers.length < coverPool.length)
		{
			var number = Math.round (coverPool.length * Math.random ());
				
			var found = false;
					
			for (var j = 0; j < randomNumbers.length; j++)
			{
				if (randomNumbers[j] == number)
					found = true;
			}
									
			if (!found)
				randomNumbers.push (number);
		}

		for (var j = 0; j < randomNumbers.length; j++)
		{
			loadCover (j, randomNumbers[j])
		}

		
		onEnterFrame = undefined;
	}
	
	public function loadCover (coverPosition, poolIndex)
	{
		var book = coverPool[poolIndex];

		if (book.id == undefined)
			return;
			
		var coverView = coverArray[coverPosition];
		coverView._visible = true;
		
		coverView.cover._x = 0;
		coverView.cover._y = 0;
					
		coverView.title.text = book.title;
		coverView.id = book.id;
				
		var image = coverView.cover.createEmptyMovieClip ("image", coverView.cover.getNextHighestDepth ()); 
				
		var mclListener:Object = new Object (); 
		
		mclListener.onLoadInit = function (image:MovieClip) 
		{ 
			var filters = new Array ();
			filters.push (new flash.filters.BlurFilter (1.15, 1.15, 3));
			
			var shadow = new flash.filters.DropShadowFilter ();
			
			shadow.alpha = 0.5;
			
			filters.push (shadow); 

			image.filters = filters;
				
			image._y = image._parent.paper._height - image._height;
			image._x = (image._parent.paper._width - image._width) / 2;
						
			image._alpha = 80;
					
			image.onRollOver = function ()
			{
				this._alpha = 100;
			}

			image.onRollOut = function ()
			{
				this._alpha = 80;
			}

			image.onPress = function ()
			{
				getURL ("books/" + this._parent._parent.id + "/index.html");						
			}
		}
				
		mclListener.onLoadError = function (target_mc:Object, errorCode:String) 
		{ 
			trace ("ERROR - " + errorCode);
		}
				 
		trace ("loading " + "books/" + coverView.id + "/thumbnail.png");
		var image_mcl:MovieClipLoader = new MovieClipLoader (); 
		image_mcl.addListener (mclListener); 
		image_mcl.loadClip ("books/" + coverView.id + "/thumbnail.png", coverView.cover.image);

		coverArray[coverPosition]._visible = true;
	}
}
