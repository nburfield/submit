$(document).on("click", "#run_submission", function(){
	doPoll();
	
	
});

function doPoll(){
		//$.get('http://localhost:3000', function(poll){
			
			//setTimeout(doPoll, 10000);
			//alert(poll);
			//alert("success");
		//});
		$.ajax({
			url: "http://localhost:3000/api_submission/poll/1",
			type: "GET",
			datatype: "json",

			success: function(data) {
				console.log("POLLING");
			},
			
			//complete : setTimeout(function() {doPoll()}, 5000),
		});

		
}