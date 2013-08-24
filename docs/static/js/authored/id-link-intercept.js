/*-----------------------------
------ INTERCEPT ID LINKS -----
-----------------------------*/

var links = $( "a[href^='#']" );
$.each( links, function( index, link ) {

    var href = $( link ).attr( 'href');
    var $el = $( href );
    
    // If this links to somewhere deeper on the page,
    // listen to click event.
    if ( $el.length > 0 ) {

        $( link ).click( function() {
            // Set hash.
            window.location.hash = $( link ).attr( 'href');
            // Twirl open the enclosing protected section, if applicable.
            var subsection = $el.closest( '.protected-subsection__body' );
            twirlOpen( subsection );
            // Jump to the section.
            $('html, body').animate( {
                scrollTop: $el.offset().top - 80
            }, 250, 'easeInOutQuad' );
            return false;
        } );
    }

} );

/*-----------------------------
----- INTERCEPT DEEP LINKS ----
-----------------------------*/

// If there's a hash link in the URL, scroll to it.
setTimeout( function() {

    window.scrollTo( 0, 0 );

    if ( window.location.hash ) {
        var $el = $( window.location.hash );
        $('html, body').animate( {
            scrollTop: $el.offset().top - 80
        }, 250, 'easeInOutQuad' );
    }

}, 10 );