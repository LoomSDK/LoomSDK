/*-----------------------------
------ BUILD SIDEBAR NAV ------
-----------------------------*/

if(!this.sidebarData) {
    alert('Undefined sidebarData!');
}

// Recursively construct sidebar DOM.
var sidebarId = 0;
var sidebarDom = makeList( sidebarData, 0, '' );
$( '.sidebar__body' ).append( sidebarDom );

function makeList( obj, depth, id ) {
    var list = $( '<ul id="' + id + '"></ul>' );
    _.each( obj, function( itemData ) {
        
        var listItemDom = makeListItem( itemData[ "name" ], depth );
        var link = itemData[ "link" ];

        if ( _.isString( link ) ) {
            
            // If link goes somewhere, add an anchor.
            listItemDom.append( makeLink( link ) );

        } else {
            
            // Else, we assume link contains an object
            // of children, so we add a list we can twirl down.
            var linkDom = makeLink( '#' );
            listItemDom.append( linkDom );
            var listDom = makeList( link, depth + 1, id );
            listItemDom.addClass( 'twirlable' );
            listItemDom.append( listDom );
            listDom.hide();
            linkDom.click( function() {
                listItemDom.toggleClass( 'twirlable--open' );
                listDom.toggle();
                return false;
            } );

        }

        list.append( listItemDom );
    } );
    return list;
}

function makeListItem( name, depth ) {
    var listItem = $( '<li>' ).addClass( 'sidebar__body__item' );
    listItem.append( $( '<span>' ).text( name ).addClass( 'sidebar__body__item__text' ) );
    return listItem;
}

function makeLink( link ) {
    return $( '<a href="' + link + '"><span class="block-link"></span></a>' );
}

/*-----------------------------
-------- SHOW SIDEBAR ---------
-----------------------------*/

var sidebar = $( '#sidebar' );

var sidebarDelay;

// Show sidebar on mouseover.
sidebar.mouseover( function() {
    clearTimeout( sidebarDelay );
    sidebar.removeClass( 'sidebar--hidden' );
} );

// Hide sidebar on mouseout, after a brief delay.
sidebar.mouseout( function() {
    clearTimeout( sidebarDelay );
    sidebarDelay = setTimeout( function() {
    sidebar.addClass( 'sidebar--hidden' );
    }, 10 );
} );