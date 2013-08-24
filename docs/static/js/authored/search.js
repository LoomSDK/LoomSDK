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

$(document).keyup( function(event) {
  if(event.which == 83)
    input.focus();
});

dropdown.on('show', function(){
  if(input.val().length == 0)
    dropdown.hide();
});

options.hide();

input.click( function() {
  input.val("");
});

button.click( function() {
  toggleSearchMenu();
})

input.focus( function() {
  if($(document.activeElement)[0] != input[0])
    input.val("");
});

button.click( function() {
  return false;
} );

input.keyup( function(event) {
  
  var list = dropdown.find("li");
  if(event.which == 27)
  {
    input.val("");
    dropdown.hide();
    return;
  }
  
  if(event.which == 13)
  {
    if($(".hovered a")[0])
      $(".hovered a")[0].click();
    else if(dropdown.find("a")[0])
      dropdown.find("a")[0].click();
    return;
  }
  
  if(event.which == 38)
  {
    var lastSelectedItem = $(".hovered");
    var latestSelectedIndex = list.index(lastSelectedItem);
    if(list[latestSelectedIndex-1])
    {
      lastSelectedItem.removeClass("hovered");
      $(list[latestSelectedIndex-1]).addClass('hovered');
    }
    return;
  }
  
  if(event.which == 40)
  {
    var lastSelectedItem = $(".hovered");
    var latestSelectedIndex = list.index(lastSelectedItem);
    if(list[latestSelectedIndex+1])
    {
      lastSelectedItem.removeClass("hovered");
      $(list[latestSelectedIndex+1]).addClass('hovered');
    }
    return;
  }
  
  var fuseOptions = {
    keys: ['path', 'name'],
    threshold: 0.3
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
      fuseArray = search_objects.classes.concat(search_objects.examples).concat(search_objects.guides);
  }
  
  
  var f = new Fuse(fuseArray, fuseOptions);
  results = f.search(input.val());
  for(var index = 0; (index < 20 && index < results.length); index++)
  {
    var link = "";
    if(relative_base == "")
      link = results[index].path.split(".").join("/") + ".html"
    else
      link = relative_base + "/" + results[index].path.split(".").join("/") + ".html";
      
    search_results.append("<li><a href='" + link + "'>" + results[index].name + "</a></li>");
  }
});

$.each( optionsList, function( index, el ) {
  var $el = $( el );
  $el.click( function() {
    selectSearchItem( $el );
    hideSearchMenu();
    return false;
  } );
} );

$( document ).click( function() {
  search_results.html("");
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