$(document).ready(function(){

	var isInputContainerOn = true;

	// make the side panel movable
	$( "#side-bar-container" ).draggable({ containment: "parent" });

 	$("#min-max-button").click(function(){

 		console.log("Display the panel with inputs");

 		// if the input container is on, hide it
 		if (isInputContainerOn) {
 			$("#input-container").slideUp("slow");

			// change the icons depending of the side bar staly (on or Off)
			$("#min-max-icon").switchClass( "glyphicon-minus", "glyphicon-plus", 1000, "easeInOutQuad" );

 			isInputContainerOn = false;
 		} else { // if not display it
 			$("#input-container").slideDown("slow");

			// change the icons depending of the side bar staly (on or Off)
			$("#min-max-icon").switchClass( "glyphicon-plus", "glyphicon-minus", 1000, "easeInOutQuad" );
			
 			isInputContainerOn = true;
 		}

 	});
});
