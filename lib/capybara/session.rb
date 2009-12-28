module Capybara
  
  class TimeoutError < RuntimeError; end
  
  class Session
    include Searchable
    
    attr_reader :mode, :app

    def initialize(mode, app)
      @mode = mode
      @app = app
    end
    
    def driver
      
      @driver ||= case mode
      when :rack_test
        Capybara::Driver::RackTest.new(app)
      when :selenium
        Capybara::Driver::Selenium.new(app)
      when :celerity
        Capybara::Driver::Celerity.new(app)
      when :culerity
        Capybara::Driver::Culerity.new(app)
      else
        raise Capybara::DriverNotFoundError, "no driver called #{mode} was found"
      end
    end

    def current_url
      driver.current_url
    end
    
    def response_headers
      driver.response_headers
    end
    
    def visit(path)
      driver.visit(path)
    end

    def click(locator)
      link = autowait_find(XPath.link(locator).button(locator))
      raise Capybara::ElementNotFound, "no link or button '#{locator}' found" unless link
      link.click
    end

    def click_link(locator)
      link = autowait_find(XPath.link(locator))
      raise Capybara::ElementNotFound, "no link with title, id or text '#{locator}' found" unless link
      link.click
    end

    def click_button(locator)
      button = autowait_find(XPath.button(locator))
      raise Capybara::ElementNotFound, "no button with value or id or text '#{locator}' found" unless button
      button.click
    end

    def drag(source_locator, target_locator)
      source = autowait_find(source_locator)
      raise Capybara::ElementNotFound, "drag source '#{source_locator}' not found on page" unless source
      target = autowait_find(target_locator)
      raise Capybara::ElementNotFound, "drag target '#{target_locator}' not found on page" unless target
      source.drag_to(target)
    end

    def fill_in(locator, options={})
      field = find(XPath.fillable_field(locator), :wait => true)
      raise Capybara::ElementNotFound, "cannot fill in, no text field, text area or password field with id or label '#{locator}' found" unless field
      field.set(options[:with])
    end

    def choose(locator)
      field = autowait_find(XPath.radio_button(locator))
      raise Capybara::ElementNotFound, "cannot choose field, no radio button with id or label '#{locator}' found" unless field
      field.set(true)
    end

    def check(locator)
      field = autowait_find(XPath.checkbox(locator))
      raise Capybara::ElementNotFound, "cannot check field, no checkbox with id or label '#{locator}' found" unless field
      field.set(true)
    end

    def uncheck(locator)
      field = autowait_find(XPath.checkbox(locator))
      raise Capybara::ElementNotFound, "cannot uncheck field, no checkbox with id or label '#{locator}' found" unless field
      field.set(false)
    end

    def select(value, options={})
      field = autowait_find(XPath.select(options[:from]))
      raise Capybara::ElementNotFound, "cannot select option, no select box with id or label '#{options[:from]}' found" unless field
      field.select(value)
    end

    def attach_file(locator, path)
      field = autowait_find(XPath.file_field(locator))
      raise Capybara::ElementNotFound, "cannot attach file, no file field with id or label '#{locator}' found" unless field
      field.set(path)
    end

    def body
      driver.body
    end

    def within(kind, scope=nil)
      kind, scope = Capybara.default_selector, kind unless scope
      scope = XPath.from_css(scope) if kind == :css
      raise Capybara::ElementNotFound, "scope '#{scope}' not found on page" unless autowait_find(scope)
      scopes.push(scope)
      yield
      scopes.pop
    end

    def within_fieldset(locator)
      within XPath.fieldset(locator) do
        yield
      end
    end

    def within_table(locator)
      within XPath.table(locator) do
        yield
      end
    end

    def save_and_open_page
      require 'capybara/save_and_open_page'
      Capybara::SaveAndOpenPage.save_and_open_page(body)
    end

    def wait_for_condition(script)
      wait_until { evaluate_script(script) }
    end

    def wait_until
      return yield unless driver.wait?
      
      10.times do
        if result = yield
          return result
        end
        sleep(0.1)
      end
      
      raise TimeoutError
    end
    
    def evaluate_script(script)
      driver.evaluate_script(script)
    end

  private

    def autowait_find(locator)
      autowait = Capybara.autowait? && driver.wait? 
      find(locator, :wait => autowait)
    end
    
    def all_unfiltered(locator)
      XPath.wrap(locator).scope(current_scope).paths.map do |path|
        driver.find(path)
      end.flatten
    end
    
    def current_scope
      scopes.join('')
    end

    def scopes
      @scopes ||= []
    end
  end
end
