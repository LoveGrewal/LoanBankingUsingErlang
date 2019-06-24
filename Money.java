import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class Money {

	public static void main(String[] args) {
		List<Bank> banks = new ArrayList<Bank>();
		List<Customer> customers = new ArrayList<Customer>();
		int customerCount = 0;
		BufferedReader reader;
		System.out.println("** Banks and financial resources **");
		// reading banks.txt and creating bank threads
		try {
			reader = new BufferedReader(new FileReader("banks.txt"));
			String line = reader.readLine();
			String name;
			int money;
			while (line != null) {
				line.trim();
				line = line.substring(1, line.length() - 2);
				String[] str = line.split(",");
				name = str[0];
				money = Integer.parseInt(str[1]);
				System.out.println(name + " : " + money);
				banks.add(new Bank(money, name));
				// read next line
				line = reader.readLine();
			}
			reader.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
		System.out.println();
		System.out.println("** Customers and loan objectives **");
		// reading customers.txt and creating bank threads
		try {
			reader = new BufferedReader(new FileReader("customers.txt"));
			String line = reader.readLine();
			String name;
			int money;
			while (line != null) {
				customerCount++;
				line.trim();
				line = line.substring(1, line.length() - 2);
				String[] str = line.split(",");
				name = str[0];
				money = Integer.parseInt(str[1]);
				System.out.println(name + " : " + money);
				customers.add(new Customer(money, name, banks));
				// read next line
				line = reader.readLine();
			}
			reader.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
		System.out.println();

		// start bank threads
		for (Bank b : banks) {
			b.setCustomerCount(customerCount);
			new Thread(b).start();
		}

		// start customer thread
		for (Customer c : customers)
			new Thread(c).start();

	}

}
