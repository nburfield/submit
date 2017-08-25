$(document).on("page:change", function() {  
  $("#dropzoneUploader").dropzone({
    createImageThumbnails: false,
    success: function(file, responseText) {
      location.reload();
    }
  });
});
