$(document).on("click", "#run_submission", function(){
	//console.log("Clicked button");
	//alert("You Clicked me");
	doPoll();
	
	
});

function doPoll(){
		//$.get('http://localhost:3000', function(poll){
			
			//setTimeout(doPoll, 10000);
			//alert(poll);
			//alert("success");
		//});
		$.ajax({
			url: "http://localhost:3000/api_submission/poll",
			type: "GET",
			success: function(data) {
				console.log("POLLING");
			},
			datatype: "json",
			//complete : setTimeout(function() {doPoll()}, 5000),
		});

		
}