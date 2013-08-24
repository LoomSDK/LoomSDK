/*-----------------------------
-- TWIRL OPEN PROTECTED PROPS -
-----------------------------*/

$.each( $( '[data-twirl]' ), function( index, el ) {

    var $el = $( el );
    $el.click( function() {

        // Update state.
        $el.toggleClass( 'is-open' );

        // Open and shut hidden content.
        $( $el.attr( 'data-twirl' ) ).toggle();
        return false;

    } );

} );

function toggleTwirl( subsection ) {

    // Open subsection.
    var $subsection = $( subsection );
    $subsection.toggle();
}

function twirlOpen( subsection ) {
    subsection.toggle();
    var id = subsection.attr( 'id' );
    $( '[data-twirl=#' + id + ']' ).toggleClass( 'is-open' );
}