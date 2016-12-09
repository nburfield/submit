$(document).on("click", "#run_submission", function(){
  doPoll();
});

function doPoll(){

  var v = $('#submission').data("submission")
  this.total_run_count = 0;
  this.run_save_count = -1;

  console.log(v)
  console.log(total_run_count)
  console.log(run_save_count)

  var i = 0
  while(i < 10) {

    $.get('data/' + v.id)
      .done(function(data) {
        console.log(data.total)
        this.total_run_count = data.trc
        this.run_save_count = data.total
      });

    i += 1
  }

  console.log(v)
  console.log(this.total_run_count)
  console.log(this.run_save_count)
}
