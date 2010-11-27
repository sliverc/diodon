/*
 * Diodon - GTK+ clipboard manager.
 * Copyright (C) 2010 Diodon Team <diodon-team@lists.launchpad.net>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation, either version 2 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace Diodon
{
    /**
     * The controller is responsible to interact with all managers and views
     * passing on information between such and storing the application state
     * in the available models.
     * 
     * @author Oliver Sauder <os@esite.ch>
     */
    public class Controller : GLib.Object
    {
        private IndicatorView indicator_view;
        private ClipboardModel clipboard_model;
        private ClipboardManager clipboard_manager;
        
        /**
         * Called when a item has been selected.
         */
        private signal void on_select_item(ClipboardItem item);
        
        /**
         * Called when a new item has been available
         */
        private signal void on_new_item(ClipboardItem item);
        
        /**
         * Called when a item needs to be removed
         */
        private signal void on_remove_item(ClipboardItem item);
        
        /**
         * Called when all items need to be cleared
         */
        private signal void on_clear();
        
        /**
         * Constructor.
         * 
         * @param indicator_view diodon indicator
         * @param clipboard_model clipboard model
         * @param clipboard_manager clipboard manager
         */
        public Controller(IndicatorView indicator_view, ClipboardModel clipboard_model,
            ClipboardManager clipboard_manager)
        {            
            this.indicator_view = indicator_view;
            this.clipboard_model = clipboard_model;
            this.clipboard_manager = clipboard_manager;
        }
        
        /**
         * Connects to all necessary processes and attaches
         * such to the controller signals as well. Finally the views
         * and the models will be initialized.
         */
        public void start()
        {               
            connect_signals();
            attach_signals();
            init();
        }
        
        /**
         * connects controller to all signals of injected managers and views
         */
        private void connect_signals()
        {
            indicator_view.on_quit.connect(quit);
            indicator_view.on_clear.connect(clear);
            indicator_view.on_select_item.connect(select_item);
            
            clipboard_manager.on_clipboard_text_received.connect(text_received);
            clipboard_manager.on_primary_text_received.connect(text_received);
        }
        
        /**
         * attaches managers and views to signals of the controller
         */
        private void attach_signals()
        {
            on_select_item.connect(clipboard_manager.select_item_in_primary);
            on_select_item.connect(clipboard_manager.select_item_in_clipboard);
            on_select_item.connect(clipboard_model.select_item);
            on_select_item.connect(indicator_view.select_item);

            on_new_item.connect(clipboard_model.add_item);
            on_new_item.connect(indicator_view.prepend_item);

            on_remove_item.connect(clipboard_model.remove_item);
            on_remove_item.connect(indicator_view.remove_item);
            
            on_clear.connect(clipboard_manager.clear_primary);
            on_clear.connect(clipboard_manager.clear_clipboard);
            on_clear.connect(indicator_view.clear);
            on_clear.connect(clipboard_model.clear);
        }
        
        /**
         * Initializes views, models and managers.
         */
        private void init()
        {
             // add all available items from storage to indicator
            foreach(ClipboardItem item in clipboard_model.get_items()) {
                indicator_view.prepend_item(item);
            }
            
            clipboard_manager.start();
        }
        
        /**
         * Select item by moving it onto the top of the menu
         * respectively data storage and then copying it to the clipboard
         *
         * @param item item to be selected
         */
        private void select_item(ClipboardItem item)
        {
            on_remove_item(item);
            on_new_item(item);
            on_select_item(item);
        }
        
        /**
         * Clear all items from the clipboard and reset selected items
         */
        private void clear()
        {
            on_clear();
        }
       
        /**
         * Handling text retrieved from clipboard by adding it to the storage
         * and appending it to the menu of the indicator
         * 
         * @param text text received
         */
        private void text_received(string text)
        {
            ClipboardItem selected_item = clipboard_model.get_selected_item();
            if(selected_item == null || text != selected_item.get_text()) {
                ClipboardItem item = new ClipboardItem(text);
                
                // remove item from clipboard if it already exists
                if(clipboard_model.get_items().contains(item)) {
                    on_remove_item(item);
                }
                
                on_new_item(item);
                on_select_item(item);
            }
        }
        
        /**
         * Quit diodon
         */
        private void quit()
        {
            Gtk.main_quit();
        }
    }  
}
 
