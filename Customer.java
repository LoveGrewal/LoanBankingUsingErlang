import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class Customer implements Runnable {

	private volatile int fundsRequired;
	private String name;
	private List<Bank> availableBanks = new ArrayList<Bank>();
	private List<Bank> listToStopBankThreads = new ArrayList<>();
	private static Random random = new Random();
	private int originalfundsRequired;

	public List<Bank> getAvailableBanks() {
		return availableBanks;
	}

	public void setAvailableBanks(List<Bank> availableBanks) {
		this.availableBanks = availableBanks;
	}

	public void addAvailableBanks(Bank bank) {
		this.availableBanks.add(bank);
	}

	public int getFundsRequired() {
		return fundsRequired;
	}

	public void setFundsRequired(int fundsRequired) {
		this.fundsRequired = fundsRequired;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public Customer(int fundsRequired, String name, List<Bank> availableBanks) {
		super();
		this.fundsRequired = fundsRequired;
		this.originalfundsRequired = fundsRequired;
		this.name = name;
		for (Bank b : availableBanks) {
			this.availableBanks.add(b);
			this.listToStopBankThreads.add(b);
		}
	}

	public void makeLoanRequest() {
		try {
			int randomBankLocation = 0;
			if (availableBanks.size() > 1)
				randomBankLocation = random.nextInt(availableBanks.size() - 1);
			Bank bank = availableBanks.get(randomBankLocation);
			int requestAmount = (fundsRequired < 50) ? fundsRequired : (random.nextInt(49) + 1);
			System.out.println(this.name.toUpperCase() + " requests a loan of " + requestAmount + " dollar(s) from "
					+ bank.getName().toUpperCase());
			Thread.sleep(random.nextInt(90) + 10);
			if (bank.processLoanRequest(name, requestAmount)) {
				fundsRequired = fundsRequired - requestAmount;
			} else {
				availableBanks.remove(randomBankLocation);
			}
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}

	@Override
	public void run() {
		while (fundsRequired > 0 && availableBanks.size() > 0) {
			makeLoanRequest();
		}
		if (availableBanks.size() > 0) {
			System.out.println(this.name.toUpperCase() + " has reached the objective of " + this.originalfundsRequired
					+ " dollar(s). Woo Hoo!");
		} else {
			System.out.println(this.name.toUpperCase() + " was only able to borrow " + (this.originalfundsRequired-this.fundsRequired)
					+ " dollar(s). Boo Hoo!");
		}
		for (Bank b : listToStopBankThreads)
			b.stop();
	}

}
