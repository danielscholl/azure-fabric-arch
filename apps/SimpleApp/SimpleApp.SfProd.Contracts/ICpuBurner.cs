using Microsoft.ServiceFabric.Services.Remoting;
using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;

namespace SimpleApp.SfProd.Contracts
{
  public interface ICpuBurnerService : IService
  {
    Task<int> GetTransactionsPerSecondAsync();

    Task SetTransactionsPerSecondAsync(int transactionsPerSecond);
  }
}
