$(document).on("page:change", function() {
  $("span[data-time]").each(function (index) {
    var unixTime = $(this).text();
    var localTime = new Date();
    localTime.setTime(unixTime * 1000);

    $(this).text(formatTimeString(localTime));
  });
});

function formatTimeString(time) {
  if (isNaN(time))
    return;

  var months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  var hours = time.getHours();
  var minutes = time.getMinutes();
  var ampm = (hours >= 12) ? "pm" : "am";
  if (hours < 10)
    hours = "0" + hour;
  if (hours > 12)
    hours -= 12;

  if (minutes < 10)
    minutes = "0" + minutes;

  return months[time.getMonth()] + " " + time.getUTCDate() + ", " + time.getFullYear() + " at " + hours + ":" + minutes + " " + ampm;
}
