/*-----------------------------
---- TOGGLE INHERITED PROPS ---
-----------------------------*/

$.each( $( '.show-inherited-toggle' ), function( index, el ) {

    var $el = $( el );
    $el.click( function() {

        // Toggle checkbox on and off.
        $el.toggleClass( 'show-inherited-toggle--on' );

        // Turn all inherited items on and off.
        var $target = $( $el.attr( 'data-target' ) );
        var inherited = $target.find( '.inherited' );
        $.each( inherited, function( index, el ) {
            $( el ).toggle();
        } );

        return false;

    } );

} );