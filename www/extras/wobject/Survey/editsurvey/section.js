if (typeof Survey == "undefined") {
    var Survey = {};
}

Survey.SectionTemplate = new function(){

    this.loadSection = function(html){

        document.getElementById('edit').innerHTML = html;

        var butts = [ { text:"Submit", handler:function(){this.submit();}, isDefault:true }, { text:"Cancel", handler:function(){this.cancel();}}, 
                {text:"Delete", handler:function(){document.getElementById('delete').setValue(1); this.submit();}}
            ];

        var form = new YAHOO.widget.Dialog("section",
           { width : "500px",
             fixedcenter : true,
             visible : false,
             constraintoviewport : true,
             buttons : butts
           } );

        form.callback = Survey.Comm.callback;
        form.render();
        form.show();
    }
}();
