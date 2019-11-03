import java.sql.*;
// You should use this class so that you can represent SQL points as
// Java PGpoint objects.
import org.postgresql.geometric.PGpoint;

public class Assignment2 {

   // A connection to the database
   Connection connection;

   Assignment2() throws SQLException {
      try {
         Class.forName("org.postgresql.Driver");
      } catch (ClassNotFoundException e) {
         e.printStackTrace();
      }
   }

  /**
   * Connects and sets the search path.
   *
   * Establishes a connection to be used for this session, assigning it to
   * the instance variable 'connection'.  In addition, sets the search
   * path to uber, public.
   *
   * @param  url       the url for the database
   * @param  username  the username to connect to the database
   * @param  password  the password to connect to the database
   * @return           true if connecting is successful, false otherwise
   */
   public boolean connectDB(String URL, String username, String password) {
      // Implement this method!
      try {
      	 connection = DriverManager.getConnection(URL, username, password);
		 PreparedStatement init;
		 init = connection.prepareStatement("SET SEARCH_PATH TO uber, public");
		 init.execute();
      } catch(SQLException se){
      	System.err.println("SQL Exception." +
                        "<Message>: " + se.getMessage());
         return false;
      }
      return true;
   }

  /**
   * Closes the database connection.
   *
   * @return true if the closing was successful, false otherwise
   */
   public boolean disconnectDB() {
      // Implement this method!
      try {
		 connection.close();
      } catch(SQLException se){
      	System.err.println("SQL Exception." +
                        "<Message>: " + se.getMessage());
         return false;
      }
      return true;
   }
   
   /* ======================= Driver-related methods ======================= */

   /**
    * Records the fact that a driver has declared that he or she is available 
    * to pick up a client.  
    *
    * Does so by inserting a row into the Available table.
    * 
    * @param  driverID  id of the driver
    * @param  when      the date and time when the driver became available
    * @param  location  the coordinates of the driver at the time when 
    *                   the driver became available
    * @return           true if the insertion was successful, false otherwise. 
    */
   public boolean available(int driverID, Timestamp when, PGpoint location) {
      // Implement this method!
      try {
		 PreparedStatement execAdd = connection.prepareStatement("INSERT INTO Available VALUES (?, ?, ?)");
		 execAdd.setInt(1, driverID);
		 execAdd.setTimestamp(2, when);
		 execAdd.setObject(3, location);
		 execAdd.executeUpdate();
      } catch(SQLException se){
      	System.err.println("SQL Exception." +
                        "<Message>: " + se.getMessage());
         return false;
      }
      return true;
   }

   /**
    * Records the fact that a driver has picked up a client.
    *
    * If the driver was dispatched to pick up the client and the corresponding
    * pick-up has not been recorded, records it by adding a row to the
    * Pickup table, and returns true.  Otherwise, returns false.
    * 
    * @param  driverID  id of the driver
    * @param  clientID  id of the client
    * @param  when      the date and time when the pick-up occurred
    * @return           true if the operation was successful, false otherwise
    */
   public boolean picked_up(int driverID, int clientID, Timestamp when) {
      // Implement this method!
      try {
		  PreparedStatement execPick;
		  ResultSet rs;
		  String queryString;
		  execPick = connection.prepareStatement("select Dispatch.request_id, "
		  + "Dispatch.driver_id, Request.client_id from Dispatch, "
		  + "Request where Dispatch.request_id = Request.request_id "
		  + "and not exists (select p.request_id from Pickup p "
		  + "where Dispatch.request_id = p.request_id)");
		  // execPick.setString(1, String.valueOf(driverID));
		  rs = execPick.executeQuery();
		  while(rs.next()){
		  	int request = rs.getInt("request_id");
		  	int driver = rs.getInt("driver_id");
		  	int client = rs.getInt("client_id");
		  	if(driverID == driver){
		  		execPick = connection.prepareStatement("INSERT INTO uber.Pickup VALUES (?, ?)");
		  		execPick.setInt(1, request);
		  		execPick.setTimestamp(2, when);
		  		execPick.executeUpdate();
		  	}
		  }
      } catch(SQLException se){
      	System.err.println("SQL Exception." +
                        "<Message>: " + se.getMessage());
      	return false;
      }
      return true; 
   }
   
   public void printResult(){
	   try{
	       String queryString = "select * from available";
          PreparedStatement ps = connection.prepareStatement(queryString);

		    ResultSet rs = ps.executeQuery();

		    // Table available
		    System.out.println("available table:");
		    System.out.println();
		    while (rs.next()) {
		        int id = rs.getInt("driver_id");
		        Timestamp when = (Timestamp)(rs.getObject("datetime"));
		        PGpoint p = (PGpoint)(rs.getObject("location"));
		        System.out.println(" result: " + id + "  " + when + p);
		    }
		    System.out.println();
		    System.out.println();
		    
		    // Table Dispatch
		    System.out.println("Dispatch result: ");
		    queryString = "select * from Dispatch";
		    ps = connection.prepareStatement(queryString);
		    rs = ps.executeQuery();
		    while (rs.next()){
		    	int request = rs.getInt("request_id");
		    	int driver = rs.getInt("driver_id");
		    	PGpoint p_car = (PGpoint)(rs.getObject("car_location"));
		    	Timestamp when = (Timestamp)(rs.getObject("datetime"));
		    	System.out.println(" result: request_id:" + request + "driverID: " + driver + p_car + when);
		    }
		    System.out.println();
		    System.out.println();
		    
		    // Table Request
		    System.out.println("Request result: ");
		    queryString = "select * from Request";
		    ps = connection.prepareStatement(queryString);
		    rs = ps.executeQuery();
		    while (rs.next()){
		    	int request = rs.getInt("request_id");
		    	int client = rs.getInt("client_id");
		    	Timestamp when = (Timestamp)(rs.getObject("datetime"));
		    	System.out.println(" result: request_id:" + request + "clientID: " + client + when);
		    }
		    System.out.println();
		    System.out.println();
		    
		    // Table pickUP
		    System.out.println("picked up result: ");
		    queryString = "select * from Pickup";
		    ps = connection.prepareStatement(queryString);
		    rs = ps.executeQuery();
		    while (rs.next()){
		    	int request = rs.getInt("request_id");
		    	Timestamp when = (Timestamp)(rs.getObject("datetime"));
		    	System.out.println(" result: " + request + "  " + when);
		    }
		    System.out.println();
		    System.out.println();
	   } catch(SQLException se){
	   		System.err.println("SQL Exception." +
                        "<Message>: " + se.getMessage());
	   }
   }
   
   /* ===================== Dispatcher-related methods ===================== */

   /**
    * Dispatches drivers to the clients who've requested rides in the area
    * bounded by NW and SE.
    * 
    * For all clients who have requested rides in this area (i.e., whose 
    * request has a source location in this area), dispatches drivers to them
    * one at a time, from the client with the highest total billings down
    * to the client with the lowest total billings, or until there are no
    * more drivers available.
    *
    * Only drivers who (a) have declared that they are available and have 
    * not since then been dispatched, and (b) whose location is in the area
    * bounded by NW and SE, are dispatched.  If there are several to choose
    * from, the one closest to the client's source location is chosen.
    * In the case of ties, any one of the tied drivers may be dispatched.
    *
    * Area boundaries are inclusive.  For example, the point (4.0, 10.0) 
    * is considered within the area defined by 
    *         NW = (1.0, 10.0) and SE = (25.0, 2.0) 
    * even though it is right at the upper boundary of the area.
    *
    * Dispatching a driver is accomplished by adding a row to the
    * Dispatch table.  All dispatching that results from a call to this
    * method is recorded to have happened at the same time, which is
    * passed through parameter 'when'.
    * 
    * @param  NW    x, y coordinates in the northwest corner of this area.
    * @param  SE    x, y coordinates in the southeast corner of this area.
    * @param  when  the date and time when the dispatching occurred
    */
   public void dispatch(PGpoint NW, PGpoint SE, Timestamp when) {
      // Implement this method!
   }

   public static void main(String[] args) {
      // You can put testing code in here. It will not affect our autotester.
      try{
		  Assignment2 a2 = new Assignment2();
		  String url = "jdbc:postgresql://localhost:5432/csc343h-chengj60";
		  String user = "chengj60";
		  System.out.println("connection succeed: " + a2.connectDB(url, user, ""));
		  a2.printResult();
		  Timestamp t = new Timestamp(System.currentTimeMillis());;
		  PGpoint p1 = new PGpoint(3, 4);
		  System.out.println("available pass: " + a2.available(12345, t, p1));
		  System.out.println("pickup pass: " + a2.picked_up(12345, 1, t));
		  a2.printResult();
		  a2.disconnectDB();
	  } catch (Exception e){
	  	System.out.println("Boo!");
	  }
   }

}
