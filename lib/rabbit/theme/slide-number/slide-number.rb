proc_name = "slide-number"

@slide_number_font_size ||= @xx_small_font_size

match(Slide) do |slides|
  slides.delete_post_draw_proc_by_name(proc_name)

  slides.add_post_draw_proc(proc_name) do |slide, canvas, x, y, w, h, simulation|
    unless simulation
      text = "#{canvas.current_index}/#{canvas.slide_size - 1}"
      text = %Q[<span size="#{@slide_number_font_size}">#{text}</span>]
      layout, text_width, text_height = canvas.make_layout(text)
      layout.set_width(w * Pango::SCALE)
      layout.set_alignment(Pango::Layout::ALIGN_RIGHT)
      num_y = canvas.height - @bottom_margin - text_height
      canvas.draw_layout(layout, x, num_y)
    end
    [x, y, w, h]
  end
end
