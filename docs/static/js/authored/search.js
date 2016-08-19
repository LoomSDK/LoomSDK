/*-----------------------------
------------ SEARCH -----------
-----------------------------*/

var search = $( '#site-header__search' );
var input = search.find( 'input' );
var button = search.find( 'button' );
var options = search.find( '.options' );
var optionsList = options.find( '.options__option' );
var search_results = $( '.dropdown-menu' );
var dropdown = $( '#results-dropdown' );

// Moustache-style templates
_.templateSettings = {
  interpolate: /\{\{(.+?)\}\}/g
};

var searchResultTemplate = _.template(
  '<li class="search-result {{ kind }}"><a href="{{ link }}">' +
    '<div class="tag">{{ tag }}</div>' +
    '<div class="name">{{ name }}</div>' +
    '<div class="subtitle">{{ subtitle }}</div>' +
  '</a></li>'
);

$(document).keyup( function(event) {
  if(event.which == 83)
    input.focus();
});

dropdown.on('show', function(){
  if(input.val().length == 0)
    dropdown.hide();
});

options.hide();

button.click( function() {
  toggleSearchMenu();
})

input.focus( function() {
  if($(document.activeElement)[0] != input[0]) {
    dropdown.show();
    searchInput();
  }
});

button.click( function() {
  return false;
} );

var Keys = {
  ESCAPE: 27,
  ENTER: 13,
  UP: 38,
  DOWN: 40
}

input.keydown( function(event) {

  var list = dropdown.find("li");

  if(event.which == Keys.ESCAPE)
  {
    input.val("");
    dropdown.hide();
    return;
  }
  
  if(event.which == Keys.ENTER)
  {
    if($(".hovered a")[0])
      $(".hovered a")[0].click();
    else if(dropdown.find("a")[0])
      dropdown.find("a")[0].click();
    return;
  }

  if(event.which == Keys.UP)
  {
    var lastSelectedItem = dropdown.find(".hovered");
    var latestSelectedIndex = list.index(lastSelectedItem);
    var selectedItem = null;
    if(list[latestSelectedIndex-1])
    {
      selectedItem = $(list[latestSelectedIndex-1]);
      lastSelectedItem.removeClass("hovered");
      selectedItem.addClass('hovered');
    }
    event.preventDefault();
    scrollResultsTo(selectedItem);
    return;
  }
  
  if(event.which == Keys.DOWN)
  {
    var lastSelectedItem = dropdown.find(".hovered");
    var latestSelectedIndex = list.index(lastSelectedItem);
    if(list[latestSelectedIndex+1])
    {
      selectedItem = $(list[latestSelectedIndex+1]);
      lastSelectedItem.removeClass("hovered");
      selectedItem.addClass('hovered');
    }
    event.preventDefault();
    scrollResultsTo(selectedItem);
    return;
  }

});

input.keyup( function(event) {

  if ([
        Keys.ESCAPE,
        Keys.ENTER,
        Keys.UP,
        Keys.DOWN,
      ].indexOf(event.which) != -1) return;

  searchInput();
});

function scrollResultsTo(selectedItem) {
  var position = !selectedItem ? 0 :
    search_results.scrollTop() - search_results.height()*0.4 + 
    selectedItem.position().top + selectedItem.height()*0.5;
  
  search_results.animate({
    scrollTop: position
  }, { duration: 400, queue: false });
}

function searchInput() {

  function getExtraScore(item) {
    var score = 0;

    // Sort based on kind rarity / usefulness
    switch (item.kind)
    {
      case "guide": score -= 0.05;
      case "example": score -= 0.08;
      case "class": score -= 0.1;
    }

    return score;
  }

  
  var fuseOptions = {
    keys: ['path', 'name'],
    threshold: 0.3,
    include: ["score"],
    sortFn: function(a, b) {
      var sa = a.score + getExtraScore(a.item);
      var sb = b.score + getExtraScore(b.item);
      return sa - sb;
    },
  }
  
  if(input.val().length > 0)
  {
    dropdown.show();
  }
  else
  {
    dropdown.hide();
  }
  
  search_results.empty();
  
  // use the right array to search through
  searchWithin = options.find(".options__option--selected").attr("name");
  fuseArray = [];
  switch(searchWithin)
  {
    case "members":
      fuseArray = search_objects.members;
      break;
    case "classes":
      fuseArray = search_objects.classes;
      break;
    case "examples":
      fuseArray = search_objects.examples;
      break;
    case "guides":
      fuseArray = search_objects.guides;
      break;
    default:
      fuseArray = search_objects.classes
          .concat(search_objects.members)
          .concat(search_objects.examples)
          .concat(search_objects.guides);
  }
  
  function capitalize(str)
  {
    return str.charAt(0).toUpperCase() + str.slice(1);
  }

  function getPathExt(path)
  {
    if (!path) return path;
    if (path.substr(0, 4) == "api.") path = path.substr(4);
    if (path.substr(0, 9) == "examples.") path = path.substring(9, path.length-1-5);
    return ' <span class="faded">&mdash; ' + path + '</span>';
  }
  
  var f = new Fuse(fuseArray, fuseOptions);
  results = f.search(input.val());

  results = results.slice(0, 20);

  for(var i = 0; i < results.length; i++)
  {
    var result = results[i];
    var item = result.item;

    var r = {
      link: "",
      name: item.name,
      subtitle: item.short,
      tag: capitalize(item.kind) + getPathExt(item.path),
      kind: item.kind,
    };

    var path = item.path;
    var suffix = "";

    switch (item.kind)
    {
      case "guide":
        r.tag = capitalize(item.kind);
        break;
      case "member":
        r.tag = capitalize(item.mkind);
        r.kind += " " + item.mkind;
        pkg = classLookup["api." + item.pkg];
        if (!pkg) {
          console.warn("Unable to lookup package "+item.pkg);
          break;
        }
        path = pkg.path;
        r.tag += getPathExt(path);

        var anchorPrefix = null;
        switch (item.mkind) {
          case "method": anchorPrefix = "function"; break;
          case "constant": anchorPrefix = "constant"; break;
          case "field": anchorPrefix = "attribute"; break;
          default: console.warn("Anchor prefix not supported for " + item.mkind);
        }
        if (anchorPrefix) suffix = "#" + anchorPrefix + "-" + item.name;
        
        r.name = '<span class="faded">' + pkg.name + "</span>." + item.name;
        break;
    }

    var link = path.split(".").join("/") + ".html" + suffix;
    
    if (relative_base != "") {
      link = relative_base + "/" + link;
    }

    r.link = link;

    search_results.append(searchResultTemplate(r));
  }

  if (search_results.children().length == 0) {
    search_results.append(
      "<div class=\"no-results\">No results found for \"" + input.val() + "\".</div>");
  }
};

$.each( optionsList, function( index, el ) {
  var $el = $( el );
  $el.click( function() {
    selectSearchItem( $el );
    hideSearchMenu();
    return false;
  } );
} );

$( document ).click( function() {
  hideSearchMenu();
} );

function toggleSearchMenu() {
  options.toggle();
  button.toggleClass( 'is-pressed' );
}

function hideSearchMenu() {
  options.hide();
  button.removeClass( 'is-pressed' );
}

function selectSearchItem( $el ) {
  $.each( optionsList, function( index, el ) {
    $( el ).removeClass( 'options__option--selected' );
  } );
  $el.addClass( 'options__option--selected' );
  button.find( '.text' ).text( $el.text() );
}