Shoes.app do
    stack do
        flow do
            para "hide"
            check checked: false do |c|
                if c.checked? 
                    @hidden_slot.show
                    @el.focus # bug !
                else
                    @hidden_slot.hide
                end
            end
        end

        @hidden_slot = stack hidden: true do
            @bt = button "nothing"
            @sl = slider
            @el = edit_line ""
            @ck = check
            @rd = radio
            @pg = progress
            @eb = edit_box
            @lb = list_box
        end
    end
end