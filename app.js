$(document).ready(function(){

	var isInputContainerOn = true;

 	$("#minimize-button").click(function(){
 		
 		console.log("Display the panel with inputs");

 		// if the input container is on, hide it
 		if (isInputContainerOn) {
 			$("#input-container").slideUp("slow");
 			isInputContainerOn = false;
 		} else { // if not display it
 			$("#input-container").slideDown("slow");
 			isInputContainerOn = true;
 		}

 	});
});