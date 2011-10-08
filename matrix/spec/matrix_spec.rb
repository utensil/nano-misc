require 'capybara/rspec'

feature "Within the initial matrix" do
  background do
    # Selenium::WebDriver::Firefox::Binary.path=
    #Capybara.default_driver = :selenium
    Capybara.javascript_driver = :selenium
    #thin -R config.ru start
    @path = 'http://localhost:3000'
  end
  
  scenario "modify a matrix element", :js => true do
    visit @path
    cell = find('table#matrix tbody  tr:nth-child(1) td:nth-child(1)')
    cell.text.should == '1'
    cell.click
    #page.execute_script("alert($('table#matrix tbody  tr:nth-child(1) td:nth-child(1)').html())")
    
    within cell do
      fill_in 'value', :with => '3'
    end
    
    find('#intro').click
    
    sleep 1
    cell.text.should_not be_empty    
    cell.text.should == '3'
    
    sleep 1
  end
  
  scenario "swap rows", :js => true do
    visit @path
    
    create_dialog = find('#create-dialog')
    transform_dialog = find('#transform-dialog')
    
    create_dialog.should_not be_visible
    transform_dialog.should_not be_visible
    
    row_from = find('table#matrix tbody  tr:nth-child(1)')
    row_to = find('table#matrix tbody  tr:nth-child(2)')
    
    row_from_array = []
    row_to_array = []
    within row_from do
      all('td').each do |td|
        row_from_array << td.text.to_i
      end
    end
    
    within row_to do
      all('td').each do |td|
        row_to_array << td.text.to_i
      end
    end
    
    row_from_array.should == [1, 2, 3]
    row_to_array.should == [4, 5, 6]
    
    row_from.drag_to row_to
    
    create_dialog.should_not be_visible
    transform_dialog.should be_visible
    
    within transform_dialog do
      choose 'transform-type-swap'  
    end
    
    find('#transform-dialog ~ .ui-dialog-buttonpane .ui-dialog-buttonset button:nth-child(1)').click   
    
    transform_dialog.should_not be_visible
    
    row_from_after = find('table#matrix tbody  tr:nth-child(1)')
    row_to_after = find('table#matrix tbody  tr:nth-child(2)')
    
    row_from_array_after = []
    row_to_array_after = [] 
    
    within row_from_after do
      all('td').each do |td|
        row_from_array_after << td.text.to_i
      end
    end
    
    within row_to_after do
      all('td').each do |td|
        row_to_array_after << td.text.to_i
      end
    end
    row_from_array_after.should == [4, 5, 6]
    row_to_array_after.should == [1, 2, 3]
        
    sleep 1
  end
  
  scenario "multiply row1 with k and plus row2", :js => true do
    visit @path
    
    create_dialog = find('#create-dialog')
    transform_dialog = find('#transform-dialog')
    
    create_dialog.should_not be_visible
    transform_dialog.should_not be_visible
    
    row_from = find('table#matrix tbody  tr:nth-child(1)')
    row_to = find('table#matrix tbody  tr:nth-child(2)')
    
    row_from_array = []
    row_to_array = []
    within row_from do
      all('td').each do |td|
        row_from_array << td.text.to_i
      end
    end
    
    within row_to do
      all('td').each do |td|
        row_to_array << td.text.to_i
      end
    end
    
    row_from_array.should == [1, 2, 3]
    row_to_array.should == [4, 5, 6]
    
    row_from.drag_to row_to
    
    create_dialog.should_not be_visible
    transform_dialog.should be_visible
    
    within transform_dialog do
      #TODO choose 'transform-type-multiply-add'
      #sleep 3
      fill_in "transform-k", :with => '3'  
    end    
    
    find('#transform-dialog ~ .ui-dialog-buttonpane .ui-dialog-buttonset button:nth-child(1)').click   
    
    transform_dialog.should_not be_visible
    
    row_from_after = find('table#matrix tbody  tr:nth-child(1)')
    row_to_after = find('table#matrix tbody  tr:nth-child(2)')
    
    row_from_array_after = []
    row_to_array_after = [] 
    
    within row_from_after do
      all('td').each do |td|
        row_from_array_after << td.text.to_i
      end
    end
    
    within row_to_after do
      all('td').each do |td|
        row_to_array_after << td.text.to_i
      end
    end
    row_from_array_after.should == row_from_array
    
    0.upto 2 do |i|
      row_to_array_after[i].should == row_from_array[i] * 3 + row_to_array[i]
    end
    sleep 1
  end
  
  
end