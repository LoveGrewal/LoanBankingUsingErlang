
public class Bank implements Runnable {

	private volatile int funds;
	private volatile String name;
	public volatile int customerCount;

	public synchronized Boolean processLoanRequest(String customer, int requestAmount) {
		if ((funds - requestAmount) >= 0) {
			funds = funds - requestAmount;
			System.out.println(this.name.toUpperCase() + " approves a loan of " + requestAmount + " dollar(s) from "
					+ customer.toUpperCase());
			return true;
		}
		System.out.println(this.name.toUpperCase() + " denies a loan of " + requestAmount + " dollar(s) from "
				+ customer.toUpperCase());
		return false;
	}

	public int getCustomerCount() {
		return customerCount;
	}

	public void setCustomerCount(int customerCount) {
		this.customerCount = customerCount;
	}

	public Bank(int funds, String name) {
		super();
		this.funds = funds;
		this.name = name;
	}

	public int getFunds() {
		return funds;
	}

	public void setFunds(int funds) {
		this.funds = funds;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	@Override
	public void run() {
		while (customerCount > 0) {
			// System.out.println("Bank Server " + name + " is running.....");
		}
		System.out.println(this.name.toUpperCase() + " has " + this.funds + " dollar(s) remaining.");
	}

	public void stop() {
		customerCount--;
	}

}
